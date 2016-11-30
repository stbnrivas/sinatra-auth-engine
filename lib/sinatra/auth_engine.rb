# require "sinatra/auth/engine/version"

#puts Dir.pwd

module Sinatra
  module AuthEngine
    module Helpers

      # class Auth
      #   attr_accessor :crypted_password, :password_salt, :roles
      #   def initialize(identifier,password,roles=[])
      #     # HERE
      #   end
      # end

      class AuthEngine
        def initialize(opts=nil)
          if opts[:persistence] == 'yaml'
            @auth_engine = opts || Hash.new
            #{ :identifier => auth.crypted_password, auth.roles }
          end
        end
      end


      require 'bcrypt'
      require 'securerandom'

      class CrypterEngine
        def self.generate_salt
          BCrypt::Engine.generate_salt
        end
        def self.password_hash(password, password_salt)
          BCrypt::Engine.hash_secret(password, password_salt)
        end
      end


      # module generators
      #   include CrypterEngine
      #   class Generator
      #     # ??
      #   end
      # end

      module YamlPersistence

        def password_and_salt_password(password)
          # TODO include password restrictions verification
          password_salt = CrypterEngine::generate_salt
          password_crypted = CrypterEngine::password_hash(password, password_salt)
          return password_crypted, password_salt
        end

      end

      # module SequelPersistence
      #
      #
      # end


      # like example
      # require 'engine/version'

      # require_relative 'engine/version'
      # require_relative 'engine/engine_crypt'
      # require_relative 'engine/engine_persistence_sequel'


      # helpers AuthEngine

      # some kind of selection for configuration between
      # quick and dirty
      # yml
      # sequel

      # TO DO
      # require 'engine/engine_persistence_yml'
      # TO DO   new engine of persistence can use te template
      # require 'engine/engine_persistence_template'

    end
  end
  #register AuthEngine
end
