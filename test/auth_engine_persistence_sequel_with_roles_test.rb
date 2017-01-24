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
    @logger = Logger.new('logfile-with-roles.log')
    @logger.info("-------------   new execution   -------------")
    Authenticable.enable_logger(@logger)
  end

  def teardown
    # when end test, all Authenticable must be delete with this method

    auth_roles = AuthenticableRole.all
    auth_roles.each do |a|
      a.delete
    end
    roles = Role.all
    roles.each do |r|
      r.delete
    end
    auths = Authenticable.all
    auths.each do |a|
      Authenticable.archive_authentication(a[:identifier])
    end
  end

  def test_creation_and_deletion_of_roles_with_one_role
    assert Authenticable.create_role("role1")
    assert Authenticable.signup("user1","impenetrable",["role1"])
    activation_code = Authenticable.activation_code("user1")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user1", ["role1"]) # that already exist do at signup
    assert_nil Authenticable.authentication_by_password_with_roles?("user1","letmeguess",["role1"])
    assert_nil Authenticable.authentication_by_password_with_roles?("user1","impenetrable",["notexist"])
    refute_nil Authenticable.authentication_by_password_with_roles?("user1","impenetrable",["role1"])
    assert Authenticable.delete_roles_by_identifier("user1", ["role1"])
    assert Authenticable.archive_authentication("user1")
    assert Authenticable.delete_role("role1")
  end

  def test_creation_and_deletion_of_roles_with_multiple_roles
    assert Authenticable.create_role("role2_1")
    assert Authenticable.create_role("role2_2")
    assert Authenticable.create_role("role2_3")
    assert Authenticable.signup("user2","impenetrable")
    activation_code = Authenticable.activation_code("user2")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user2", ["role2_1"]) # that already exist do at signup
    assert Authenticable.add_roles_by_identifier("user2", ["role2_2"]) # that already exist do at signup
    refute_nil Authenticable.authentication_by_password_with_roles?("user2","impenetrable",["role2_1"])
    refute_nil Authenticable.authentication_by_password_with_roles?("user2","impenetrable",["role2_2"])
    refute_nil Authenticable.authentication_by_password_with_roles?("user2","impenetrable",["role2_1","role2_2"])
    assert_nil Authenticable.authentication_by_password_with_roles?("user2","impenetrable",["role2_3"])
    assert Authenticable.delete_roles_by_identifier("user2", ["role2_1"])
    assert Authenticable.archive_authentication("user2")
    assert Authenticable.delete_role("role2_1")
    assert Authenticable.delete_role("role2_2")
    assert Authenticable.delete_role("role2_3")
  end

  def test_signup_with_role_non_exist
    assert Authenticable.create_role("role3")
    assert Authenticable.signup("user3","impenetrable",["unknown_role"])
    # if an user/client can signup, but programmer hasn't create role previously, allow the signup
    assert Authenticable.archive_authentication("user3")
    assert Authenticable.delete_role("role3")
  end

  def test_signup_with_role_and_later_add_same_role
    assert Authenticable.create_role("role4")
    assert Authenticable.signup("user4","impenetrable",["role4"])
    assert Authenticable.add_roles_by_identifier("user4", ["role4"])
    assert Authenticable.add_roles_by_identifier("user4", ["role4"])
    # if an user/client can signup, but programmer hasn't create role previously, allow the signup
    assert Authenticable.archive_authentication("user4")
    assert Authenticable.delete_role("role4")
  end

  def test_add_role_non_existent
    assert Authenticable.signup("user5","impenetrable")
    assert Authenticable.add_roles_by_identifier("user5", ["unknown_role"])
    # TODO: above is not a bug is a feature xP, nothing is save to database.
    # maybe use a exception
    assert Authenticable.archive_authentication("user5")
  end

  def test_authentication_with_one_role_existent
    assert Authenticable.create_role("role6")
    assert Authenticable.signup("user6","impenetrable")
    activation_code = Authenticable.activation_code("user6")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user6", ["role6"])
    remember_token = Authenticable.authentication_by_password?("user6","impenetrable")
    refute_nil remember_token
    assert Authenticable.authentication_by_remember_token?(remember_token,["role6"])
    assert Authenticable.archive_authentication("user6")
    assert Authenticable.delete_role("role6")
  end

  def test_authentication_with_one_role_non_existent
    assert Authenticable.signup("user7","impenetrable")
    activation_code = Authenticable.activation_code("user7")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user7", ["role7"])
    remember_token = Authenticable.authentication_by_password?("user7","impenetrable")
    refute_nil remember_token
    refute Authenticable.authentication_by_remember_token_with_roles?(remember_token,["unknown_role"])
    assert Authenticable.archive_authentication("user7")
  end

  def test_add_role_and_authenticate_and_delete_role_and_authenticate
    assert Authenticable.create_role("role8")
    assert Authenticable.signup("user8","impenetrable")
    activation_code = Authenticable.activation_code("user8")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user8", ["role8"])
    remember_token = Authenticable.authentication_by_password?("user8","impenetrable")
    assert Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role8"])
    refute_nil remember_token
    assert Authenticable.delete_roles_by_identifier("user8",["role8"])
    refute Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role8"])
    assert Authenticable.archive_authentication("user8")
    assert Authenticable.delete_role("role8")
  end

  def test_authenticate_with_role_block_and_role_unblock
    assert Authenticable.create_role("role9")
    assert Authenticable.signup("user9","impenetrable")
    activation_code = Authenticable.activation_code("user9")
    assert Authenticable.activation!(activation_code)
    assert Authenticable.add_roles_by_identifier("user9", ["role9"])
    remember_token = Authenticable.authentication_by_password?("user9","impenetrable")
    assert Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role9"])
    assert Authenticable.block_roles(["role9"])
    refute Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role9"])
    assert Authenticable.unblock_roles(["role9"])
    assert Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role9"])
    assert Authenticable.delete_roles_by_identifier("user9",["role9"])
    refute Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role9"])
    assert Authenticable.archive_authentication("user9")
    assert Authenticable.delete_role("role9")
  end

  def test_auth_without_roles_without_activation
    assert Authenticable.create_role("role10")
    assert Authenticable.signup("user10","impenetrable")
    assert Authenticable.add_roles_by_identifier("user10", ["role10"])
    remember_token = Authenticable.authentication_by_password?("user10","impenetrable")
    assert_nil remember_token
    activation_code = Authenticable.activation_code("user10")
    assert Authenticable.activation!(activation_code)
    remember_token = Authenticable.authentication_by_password?("user10","impenetrable")
    assert Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role10"])
    assert Authenticable.delete_roles_by_identifier("user10",["role10"])
    refute Authenticable.authentication_by_remember_token_with_roles?(remember_token,["role10"])
    assert Authenticable.archive_authentication("user10")
    assert Authenticable.delete_role("role10")
  end

  def test_auth_with_multiples_tokens
  end

  def test_if_tokens_expires_are_delete_when_new_auth_success
  end

  def test_signup_with_identifier_already_in_use
    assert Authenticable.create_role("role10")
    assert Authenticable.signup("user10","impenetrable",["role10"])
    assert Authenticable.add_roles_by_identifier("user10", ["role10"])
    remember_token = Authenticable.authentication_by_password?("user10","impenetrable")
    assert_nil remember_token
    refute Authenticable.signup("user10","impenetrable")

  end

  def test_uniqueness_auth
  end

  def test_activation
    #actived?
  end

  def test_actived
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

  def test_authentication_by_remember_token
  end

  def test_authentication_until_max_token_allowed
  end

  def test_reset_password_delete_all_remember_tokens
  end

end
