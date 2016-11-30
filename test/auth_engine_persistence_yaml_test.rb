#require 'minitest'
require 'minitest/autorun'
require 'minitest/color'

require './test/test_helper'
require './lib/sinatra/auth_engine'
#require 'minitest/spec'


# this file must call from gem's root folder: sinatra-auth-engine-folder


class TestAuthEngine < MiniTest::Test

  include Sinatra::AuthEngine::Helpers
  include Sinatra::AuthEngine::Helpers::YamlPersistence


  # def setup
  #
  # end

  def test_generation
    john_doe = ["johndoe","impenetrable"]
    john_doe[2],john_doe[3] = password_and_salt_password(john_doe[1])
    refute_nil john_doe[2]
    refute_nil john_doe[3]
    refute_equal(john_doe[1],john_doe[2])
    # pass1.refute_nil cpass1
    jane_doe = ["janedoe","impenetrable"]
    jane_doe[2],jane_doe[3] = password_and_salt_password(jane_doe[1])
    refute_nil jane_doe[2]
    refute_nil jane_doe[3]
    refute_equal(jane_doe[1],jane_doe[2])
    # pass1.refute_nil cpass1
    refute_equal(john_doe[2],jane_doe[2])

  end

end
