# encoding: utf-8
# re generation
# rm test.sqlite ; sequel -m db/migrations/ sqlite://db/test.sqlite


require 'bcrypt'
require 'securerandom'

require './lib/sinatra/auth_engine'
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
      String :identifier, :unique => true
      String :password_salt
      String :password_hash
      Integer :attempts_failed, :default => MAX_ATTTEMPTED_LOGIN_FAILED
      DateTime :block_until
      String :activation_code, :default => nil
      DateTime :activation_at, :default => nil

      String :password_reset_token
      String :password_reset_token_expires_at

      String :identifier_history, :default => nil

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    create_table(:authenticable_tokens) do
      primary_key :id
      foreign_key :authenticable_id, :authenticables
      String :remember_token, :unique => true
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

    create_table(:authenticable_roles) do
      primary_key :id
      foreign_key :authenticable_id, :authenticables
      foreign_key :role_id, :roles

      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

    authenticable_roles = DB[:authenticable_roles]
    # authenticable_roles.insert(:authenticable_id => 1, role_id => 1)

    create_table(:authenticable_archives) do
      primary_key :id
      String :identifier
      String :archived_reason

      Datetime :activation_at
      Datatime :unsubscribe_at, :default => DateTime.now
      DateTime :created_at, :default => DateTime.now
      DateTime :updated_at, :default => DateTime.now
    end

  end


  down do
    drop_table(:roles)
    drop_table(:authenticables)
    drop_table(:authenticable_tokens)
    drop_table(:authenticable_roles)
    drop_table(:authenticables_archived)
  end


end
