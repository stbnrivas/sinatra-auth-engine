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





    # @db = Sequel.connect(:adapter => :sqlite, :database => 'file::memory:?cache=shared')
    # @db.tables #=> []
    # @db.create_table(:foo) { String(:foo) }
    # @db.tables #=> [:foo]
  end

  def test_creation_new_auth_without_roles
    assert Authenticable.signup("johndoe","impenetrable")
    refute Authenticable.actived?("johndoe")
    assert Authenticable.blocked?("johndoe")
    # for every role
    roles_result = DB[:roles].select(:name)
    roles = roles_result.collect{|r|r[:name]}


    roles.each do |rol|
      # puts rol
      refute Authenticable.has_roles_by_identifier?('johndoe',[rol])
    end
    #
    # Authenticable.add_roles_by_identifier("johndoe",roles)
    #   assert Authenticable.has_roles_by_identifier?('johndoe',rol[:name])
    # end
  end

  def test_signup_with_identifier_already_in_use

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
