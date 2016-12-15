#require 'minitest'
require 'minitest/autorun'
require 'minitest/color'
require 'sequel'

require './test/test_helper'
require './lib/sinatra/auth_engine'
require './lib/sinatra/engine_persistence_sequel'
#require 'minitest/spec'


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
  end

  ## test without roles
  def test_signup_with_identifier_already_in_use
    assert Authenticable.signup("admin","hackthis")
    refute Authenticable.signup("admin","iwillhackyou")
    assert Authenticable.archive_authentication("admin")
  end

  def test_creation_new_auth_and_activate_and_authenticate_and_block
    assert Authenticable.signup("johndoe","impenetrable")
    refute Authenticable.active?("johndoe")
    assert Authenticable.block?("johndoe")
    # for every role
    roles_result = DB[:roles].select(:name)
    roles = roles_result.collect{|r|r[:name]}
    roles.each do |rol|
      refute Authenticable.has_roles_by_identifier?('johndoe',[rol])
    end
    refute_nil Authenticable.activation?("johndoe")
    activation_code = Authenticable.activation_code("johndoe")
    assert Authenticable.activate!(activation_code)
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
    refute Authenticable.active?("janedoe")
    refute_nil Authenticable.activation?("janedoe")
    refute Authenticable.authentication_by_password?("janedoe","janerules!")
    assert Authenticable.archive_authentication("janedoe")
  end

  def test_auth_with_multiples_tokens
    # MAX_DEVICES_AUTHORIZED_ALLOWED
    assert Authenticable.signup("johnconnor","wearegoingtodieall")
    activation_code = Authenticable.activation_code("johnconnor")
    assert Authenticable.activate!(activation_code)
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
    assert Authenticable.activate!(activation_code)
    refute Authenticable.activate!(activation_code)
    assert Authenticable.archive_authentication("sarahconnor")
  end

  def test_activation_unsuccessful
    activation_code = Authenticable.activation_code("sarahconnor")
    refute Authenticable.activate!(activation_code)
    assert Authenticable.archive_authentication("sarahconnor")
  end

  def test_uniqueness_auth
  end

  def test_block
  end

  def test_unblock
  end

  def test_reset_password
  end

  def test_new_password
  end

  def test_if_reset_password_remove_all_token_authenticable_tokens
  end

  def test_if_authentication_delete_expires_tokens
  end

  def test_change_identifier_for_already_in_use
  end

  def test_change_identifier_for_one_free
    #test identifier_history works
  end

  def test_add_roles
  end

  def test_remove_roles
  end

  def test_block_roles
  end

  def test_unblock_roles
  end

  def test_authentication_by_password
  end

  def test_has_roles

  end

  def test_authentication_by_remenber_token
  end

  def test_authentication_until_max_token_allowed
  end

  def test_reset_password_delete_all_remenber_tokens
  end

end
