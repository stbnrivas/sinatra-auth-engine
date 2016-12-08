# encoding: utf-8
#
# rm database.sqlite ; sequel -m migrations/ sqlite://database.sqlite --trace
#

# require '../../lib/sinatra/engine_crypt'
# require '../lib/sinatra/engine_crypt'
require './lib/sinatra/auth_engine'

include Sinatra::AuthEngine::Helpers

Sequel.migration do

  up do

    roles = DB[:roles]
    # roles.insert(:name => 'root')

    authenticables = DB[:authenticables]

    # password_clean = Array.new(5){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
    password_clean = "qwerty"
    password_salt = CrypterEngine.generate_salt
    authenticables.insert(:identifier => 'admin',
    :password_salt => password_salt,
    :password_hash => CrypterEngine.password_hash(password_clean, password_salt),
    :activation_code => Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join,
    :attempts_failed => MAX_ATTTEMPTED_LOGIN_FAILED,
    :block_until => Time.now )
    user001_id = DB["select id from authenticables where identifier='user001' "]


    authenticable_tokens = DB[:authenticable_tokens]
    # remember_token = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join

    authenticable_roles = DB[:authenticable_roles]
    # authenticable_roles.insert(:authenticable_id => 1, role_id => 1)



  end


  down do
    #TO DO
  end


end
