#require 'minitest'
require 'minitest/autorun'
require 'minitest/color'
require 'sequel'
# require 'minitest/debugger'

require './test/test_helper'
require './lib/sinatra/auth_engine'
require './lib/sinatra/engine_persistence_sequel'
#require 'minitest/spec'

require 'logger'
# this file must call from gem's root folder: sinatra-auth-engine-folder

class TestAuthEngine < MiniTest::Test
  include Sinatra::AuthEngine::Helpers
  include Sinatra::AuthEngine::Helpers::PersistenceSequel

  def setup
    #No database associated with Sequel::Model: have you called Sequel.connect or Sequel::Model.db=
    # creation of database
    # remove database
    # @db = Sequel.connect(:adapter => :sqlite, :database => 'file::memory:?cache=shared')
    # @db.tables #=> []
    # @db.create_table(:foo) { String(:foo) }
    # @db.tables #=> [:foo]
    @logger = Logger.new('logfile.log')
    @logger.info("-------------   new execution   -------------")
    Authenticable.enable_logger(@logger)
  end

  def teardown
    # when end test, all Authenticable must be delete with this method
    # like opposite of setup
    auths = Authenticable.all
    auths.each do |a|
      Authenticable.archive_authentication(a[:identifier])
    end
  end

  ## test without roles
  def test_signup_with_identifier_already_in_use
    assert Authenticable.signup("admin","hackthis")
    refute Authenticable.signup("admin","iwillhackyou")
    assert Authenticable.archive_authentication("admin")
  end

  def test_i_can_authenticate_without_activation_done
    assert Authenticable.signup("admin2","hackthis")
    assert_nil Authenticable.authentication_by_password?("admin2","hackthis")
    activation_code = Authenticable.activation_code("admin2")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.activation?("admin2")
    refute_nil Authenticable.authentication_by_password?("admin2","hackthis")
    assert Authenticable.archive_authentication("admin2")
  end

  def test_creation_new_auth_and_activate_and_authenticate_and_block
    assert Authenticable.signup("johndoe","impenetrable")
    refute Authenticable.activation?("johndoe")
    refute Authenticable.block?("johndoe")
    # for every role
    roles_result = DB[:roles].select(:name)
    roles = roles_result.collect{|r|r[:name]}
    roles.each do |rol|
      refute Authenticable.has_roles_by_identifier?('johndoe',[rol])
    end
    refute_nil Authenticable.activation?("johndoe")
    activation_code = Authenticable.activation_code("johndoe")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.activation?("johndoe")
    authentication_token = Authenticable.authentication_by_password?("johndoe","impenetrable")
    assert Authenticable.authentication_by_remember_token?(authentication_token)
    for i in 1..Authenticable.max_attempted_login_failed
      refute Authenticable.authentication_by_password?("johndoe","impenetrable?")
    end
    refute Authenticable.authentication_by_remember_token?("authentication_token")
    assert Authenticable.archive_authentication("johndoe")
  end


  def test_auth_without_roles_without_activation
    assert Authenticable.signup("janedoe","janerules!")
    refute Authenticable.activation?("janedoe")
    refute_nil Authenticable.activation?("janedoe")
    refute Authenticable.authentication_by_password?("janedoe","janerules!")
    assert Authenticable.archive_authentication("janedoe")
  end

  def test_auth_with_multiples_tokens
    # MAX_DEVICES_AUTHORIZED_ALLOWED
    assert Authenticable.signup("johnconnor","wearegoingtodieall")
    activation_code = Authenticable.activation_code("johnconnor")
    assert Authenticable.activation!(activation_code)
    tokens = []
    for i in 0..Authenticable.max_device_authorized_allowed-1
      tokens << Authenticable.authentication_by_password?("johnconnor","wearegoingtodieall")
      refute_nil tokens[i]
    end
    tokens.each do |token|
      assert Authenticable.authentication_by_remember_token?(token)
    end
    assert Authenticable.archive_authentication("johnconnor")
  end


  def test_if_tokens_expires_are_delete_when_new_auth_success
    #how i get one auth with tokens expired?, default into a migration
    # more ideas?
  end

  def test_activation_over_already_activate
    assert Authenticable.signup("sarahconnor","wearegoingtodieall")
    activation_code = Authenticable.activation_code("sarahconnor")
    assert Authenticable.activation!(activation_code)
    refute Authenticable.activation!(activation_code)
    assert Authenticable.archive_authentication("sarahconnor")
  end

  def test_activation_that_not_exist
    activation_code = Authenticable.activation_code("t1000")
    refute Authenticable.activation!(activation_code)
  end

  def test_block_and_unblock_without_activation
    # without activation can not authenticate_by_password and don't decrement remain attempts until block
    assert Authenticable.signup("t800","iservetojohnconnor")
    refute Authenticable.block?("t800")
    assert Authenticable.block!("t800")
    assert Authenticable.block?("t800")
    assert Authenticable.unblock!("t800")
    refute Authenticable.block?("t800")
    assert Authenticable.archive_authentication("t800")
  end

  def test_block_and_unblock_with_activation
    assert Authenticable.signup("t801","iservertojohnconnor")
    activation_code = Authenticable.activation_code("t801")
    assert Authenticable.activation!(activation_code)
    refute Authenticable.block?("t801")
    assert Authenticable.block!("t801")
    assert Authenticable.block?("t801")
    assert Authenticable.unblock!("t801")
    refute Authenticable.block?("t801")
    assert Authenticable.archive_authentication("t801")
  end

  def test_block_unblock_by_remain_attempts
    assert Authenticable.signup("t802","iservertojohnconnor")
    activation_code = Authenticable.activation_code("t802")
    assert Authenticable.activation!(activation_code)
    for i in 1..Authenticable.max_attempted_login_failed
      refute Authenticable.block?("t802")
      refute Authenticable.authentication_by_password?("t802","segmentfault")
    end
    assert Authenticable.block?("t802")
    refute Authenticable.authentication_by_password?("t802","iservertojohnconnor")
    assert Authenticable.unblock!("t802")
    assert Authenticable.authentication_by_password?("t802","iservertojohnconnor")
    assert Authenticable.archive_authentication("t802")
  end


  def test_reset_password_and_set_new_password
    assert Authenticable.signup("t803","iservertojohnconnor")
    # test without activation i can not login untill activate account
    password_reset_token = Authenticable.reset_password!("t803")
    assert_nil password_reset_token
    refute Authenticable.authentication_by_password?("t803","iservertojohnconnor")
    refute Authenticable.new_password!(password_reset_token,"iservertojohnconnoragain")
    refute Authenticable.authentication_by_password?("t803","iservertojohnconnoragain")
    assert_empty Authenticable.remember_tokens_by_identifier("t803")
    # test with activation
    activation_code = Authenticable.activation_code("t803")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.authentication_by_password?("t803","iservertojohnconnor")
    refute_empty Authenticable.remember_tokens_by_identifier("t803")
    password_reset_token = Authenticable.reset_password!("t803") # new_password! disable all tokens of authentication, disable with current identifier and password
    refute_nil password_reset_token
    assert Authenticable.new_password!(password_reset_token,"iservetoskynet")
    assert Authenticable.authentication_by_password?("t803","iservetoskynet")
    refute_empty Authenticable.remember_tokens_by_identifier("t803")
    assert Authenticable.archive_authentication("t803")
  end

  def test_reset_password_when_another_reset_password_in_time_and_ignore_nexts
    assert Authenticable.signup("t804","iservertoskynet")
    refute Authenticable.authentication_by_password?("t804","iservertoskynet")
    password_reset_token = Authenticable.reset_password!("t804")
    assert_nil password_reset_token
    refute Authenticable.new_password!(password_reset_token,"iservertojohnconnor")
    # test with activation
    activation_code = Authenticable.activation_code("t804")
    assert Authenticable.activation!(activation_code)
    password_reset_token = Authenticable.reset_password!("t804")
    assert Authenticable.new_password!(password_reset_token,"iservertojohnconnor")
  end

  def test_if_authentication_delete_expires_tokens
  end

  def test_change_identifier_for_already_in_use
  end

  def test_change_identifier_for_one_free
    #test identifier_history works
  end

  def test_authentication_by_remember_token
    assert Authenticable.signup("t805","iservertoskynet")
    # test with activation
    activation_code = Authenticable.activation_code("t805")
    assert Authenticable.activation!(activation_code)
    tokens = []
    for i in 0..Authenticable.max_device_authorized_allowed-1
      tokens << Authenticable.authentication_by_password?("t805","iservertoskynet")
      refute_nil tokens[i]
    end
    tokens.each do |t|
      assert Authenticable.authentication_by_remember_token?(t)
    end
    refute Authenticable.authentication_by_remember_token?("this-is-an-fake-remember-token-make-to-fail")
    assert_raises RuntimeError do
      Authenticable.authentication_by_password?("t805","iservertoskynet")
    end
  end

end
