# encoding: utf-8
#
# rm database.sqlite ; sequel -m migrations/ sqlite://database.sqlite --trace
#

require 'bcrypt'
require 'securerandom'

require '../lib/sinatra/auth_engine'
include Sinatra::AuthEngine::Helpers

MAX_ATTTEMPTED_LOGIN_FAILED = 7

# require 'auth_engine'
# require '../../lib/sinatra/engine_crypt'



Sequel.migration do

  up do

    create_table(:roles) do
      primary_key :id
      String :name
      String :status, :default => 'enable'

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    roles = DB[:roles]
    roles.insert(:name => 'root')
    roles.insert(:name => 'devops')
    roles.insert(:name => 'bofh')
    roles.insert(:name => 'user')



    create_table(:authenticables) do
      primary_key :id
      String :identifier
      String :password_salt
      String :password_hash
      Integer :attempts_failed, :default => MAX_ATTTEMPTED_LOGIN_FAILED
      DateTime :block_until
      String :activation_code
      DateTime :activated_at

      String :password_reset_token
      String :password_reset_token_expires_at

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    authenticables = DB[:authenticables]

    password_clean = Array.new(5){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
    password_salt = BCrypt::Engine.generate_salt
    authenticables.insert(:identifier => 'user001',
    :password_salt => password_salt,
    :password_hash => BCrypt::Engine.hash_secret(password_clean, password_salt),
    :activation_code => Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join,
    :attempts_failed => MAX_ATTTEMPTED_LOGIN_FAILED,
    :block_until => Time.now )
    user001_id = DB["select id from authenticables where identifier='user001' "]



    create_table(:authenticable_tokens) do
      primary_key :id
      foreign_key :authenticable_id
      String :remember_token
      DateTime :remember_token_begin_at
      DateTime :remember_token_expires_at
      String :device
      # greetings to NSA, don't be evil.
      # String :ip
      # String :device
      # String :browser

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    authenticable_tokens = DB[:authenticable_tokens]
    authenticable_tokens.insert(:authenticable_id => user001_id,
      :remember_token => Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join,
      :remember_token_begin_at => Time.now,
      :remember_token_expires_at => Time.now + (2*7*24*60*60)
       )

    # remember_token = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
    #

    create_table(:authenticable_roles) do
      primary_key :id
      foreign_key :authenticable_id, :authenticable
      foreign_key :role_id, :roles

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    authenticable_roles = DB[:authenticable_roles]
    # authenticable_roles.insert(:authenticable_id => 1, role_id => 1)



  end


  down do
    drop_table(:roles)
    drop_table(:authenticable)
    drop_table(:authenticable_tokens)
    drop_table(:authenticable_roles)
    #TO DO
  end


end
