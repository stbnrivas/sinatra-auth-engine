module Sinatra
  module AuthEngine
    module Helpers
      module PersistenceSequel




        # TODO list
        # - when detect into db more than @@max_attempted_login_failed reset
        # - when user reset password all tokens_authentication must be deleted
        # - when resend token of activation send diferent every time
        # - when send token of password send diferent every time

        require 'sequel'

        class Role < Sequel::Model
          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :name
        end

        class AuthenticableRole < Sequel::Model
          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :identifier_authenticable
          # attr_reader :role_name
        end

        class AuthenticableToken < Sequel::Model
          # id
          # authenticable_id
          # remember_token
          # remember_token_begin_at
          # remember_token_expires_at
          # created_at
          # updated_at
        end

        class AuthenticableArchive < Sequel::Model

        end

        class Authenticable < Sequel::Model

          # TODO:
          @@configuration = Hash.new(:deny_authenticate_until_activation => true)

          @@max_attempted_login_failed = 7
          @@max_device_authorized_allowed = 5
          @@time_expiration_token = (2*7*24*60*60) # 2 Weeks
          @@password_reset_expires =  2*60*60 # 2 Hours
          @@time_disable_login_to_excced_max_login = 2*60*60 # 2 Hours

          def self.enable_logger(logger)
            @@logger = logger
          end

          def self.max_attempted_login_failed
            @@max_attempted_login_failed
          end
          def self.max_device_authorized_allowed
            @@max_device_authorized_allowed
          end

          def self.time_disable_login_to_excced_max_login
            @@time_disable_login_to_excced_max_login
          end
          def self.time_disable_login_to_excced_max_login
            @@time_disable_login_to_excced_max_login
          end

          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans, Thanks
          # attr_reader :index # database index autoincrement
          # attr_reader :identifier
          # attr_reader :password_salt
          # attr_reader :password_hash
          # attr_reader :remain_attempts_until_block
          # attr_reader :block_until
          # attr_reader :activation_code
          # attr_reader :activation_at
          # attr_reader :password_reset_token
          # attr_reader :password_reset_token_expires_at

          # return true if auth not already in use and user signup success
          def self.signup(identifier, password, roles=nil)
            result = false
            current_auth = Authenticable.find(:identifier => identifier)
            if current_auth.nil?
              password_salt = CrypterEngine.generate_salt
              password_hash = CrypterEngine.password_hash( password, password_salt)
              activation_code = Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
              new_authenticable = Authenticable.new( :identifier => identifier,
                :password_hash => password_hash,
                :password_salt => password_salt,
                :remain_attempts_until_block => @@max_attempted_login_failed,
                :activation_code => activation_code)
              new_authenticable.save
              # check if roles exist for add AuthenticableRole
              unless roles.nil?
                self.add_roles_by_identifier(identifier,roles)
              end
              result = true
            else
              result = false
            end
            return result
          end

          def self.change_identifier(old_identifier,new_identifier,attempted_password)
            # TODO
          end

          def self.activation_code(identifier)
            result = nil
            current_auth = Authenticable.find(:identifier => identifier)
            result = current_auth[:activation_code] unless current_auth.nil?
            return result
          end

          def self.activation?(identifier)
            result = false
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              result = true if (current_auth[:activation_at].is_a?(Time) and (Time.now > current_auth[:activation_at]) and current_auth[:activation_code].nil?)
            end
            return result
          end

          def self.activation!(activation_code)
            result = false
            current_auth = Authenticable.find(:activation_code => activation_code)
            unless current_auth.nil?
              current_auth[:activation_at] = Time.now
              current_auth[:activation_code] = nil
              current_auth.save
              result = true
            end
            return result
          end

          def self.reset_password?(identifier)
            result = false
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              result = true unless current_auth[:password_reset_token].nil? or current_auth[:password_reset_token].empty?
            end
          end

          # return password_reset_token or nil if fail
          def self.reset_password!(identifier)
            result = nil
            current_auth = Authenticable.find(:identifier => identifier)
            if !current_auth.nil? and Authenticable.activation?(identifier)
              result = Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
              current_auth[:password_reset_token] = result
              current_auth[:password_reset_token_expires_at] = Time.now + @@password_reset_expires
              current_auth.save
            end
            return result
          end

          def self.new_password!(password_reset_token,new_password)
            result = false
            current_auth = Authenticable.find(:password_reset_token => password_reset_token)
            if !current_auth.nil? and Authenticable.reset_password?(current_auth[:identifier])
              password_salt = CrypterEngine.generate_salt
              password_hash = CrypterEngine.password_hash(new_password,password_salt)
              current_auth[:password_salt] = password_salt
              current_auth[:password_hash] = password_hash
              current_auth[:password_reset_token] = nil
              current_auth[:password_reset_token_expires_at] = nil
              current_auth.save
              # remove all tokens
              tokens = AuthenticableToken.filter(:id => current_auth[:id])
              tokens.each do |t|
                t.destroy
              end
              result = true
            end
            return result
          end

          def self.add_roles_by_identifier(identifier, roles)
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Role.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRole.find(:authenticable_id => current_auth[:id], :role_id => current_role[:id])
                  if ur.nil?
                    # TODO: think about current_auth[:id]
                    ur = AuthenticableRole.new(:authenticable_id => current_auth[:id], :role_id => current_role[:id],:status => 'enable')
                    ur.save
                  end
                end
              end
            end
            raise NotImplementedYet
          end


          def self.add_roles_by_remember_token(remember_token, roles)
            #current_auth = Authenticable.find(:remember_token => remember_token)
            auth_token = AuthenticableToken.find(:remember_token => remember_token)
            current_auth = Authenticable.find(:id => auth_token[:id])
            self.add_roles_by_identifier(current_auth[:identifier],roles)
          end


          def self.remove_roles(remember_token,roles)
            current_auth = Authenticable.find(:remember_token => remember_token)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Role.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRole.find(:authenticable_id => current_auth[:id], :role_id => current_role[:id])
                  unless ur.nil?
                    ur.destroy
                  end
                end
              end
            end
          end

          def self.block_roles(remember_token,roles)
            current_auth = Authenticable.find(:remember_token => remember_token)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Role.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRole.find(:user_id => current_auth[:id], :role_id => current_role[:id])
                  unless ur.nil?
                    ur[:status] = 'disable'
                    ur.save
                  end
                end
              end
            end
          end

          def self.unblock_roles(remember_token,roles)
            current_auth = Authenticable.find(:remember_token => remember_token)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Role.find(:name => role)
                unless current_role.nil?
                  ur = AuthenticableRole.find(:user_id => current_auth[:id], :role_id => current_role[:id])
                  unless ur.nil?
                    ur[:status] = 'enable'
                    ur.save
                  end
                end
              end
            end
          end



            # check is user is block by exceed @@max_attempted_login_failed<1 times bad login
            def self.block?(identifier)
              result = false
              u = Authenticable.find(:identifier => identifier)
              # puts "block? remain:#{u[:remain_attempts_until_block]} block_until:#{u[:block_until]}"
              unless u.nil?
                result = true if (u[:remain_attempts_until_block]<1) or ((not u[:block_until].nil?) and (Time.now < u[:block_until]))
              end
              # puts result
              return result
            end

            # unblock the user access
            def self.block!(identifier)
              u = Authenticable.find(:identifier => identifier)
              unless u.nil?
                u[:remain_attempts_until_block] = 0
                u[:block_until] = nil
                u.save
              end
            end

            # unblock the user access
            def self.unblock!(identifier)
              u = Authenticable.find(:identifier => identifier)
              unless u.nil?
                u[:remain_attempts_until_block] = @@max_attempted_login_failed
                u[:block_until] = nil
                u.save
              end
            end


          ## return remember_token if accepted or nil in other case
          def self.authentication_by_password?(attempted_identifier, attempted_password)
            result = nil
            current_auth = Authenticable.find(:identifier => attempted_identifier)
            unless current_auth.nil?
              if (current_auth[:password_reset_token].nil? or current_auth[:password_reset_token].empty?) and
                ((current_auth[:block_until].nil?) or ( (Time.now > current_auth[:block_until]) and (current_auth[:remain_attempts_until_block] > 0) ))
                attempted_password_hash = CrypterEngine.password_hash(attempted_password,current_auth[:password_salt])
                # confirm password and user has been activated
                if current_auth[:activation_at].nil?
                  # TODO
                  # raise DENY_AUTHENTICATION_UNTIL_ACTIVATION if @@configuration[:deny_authenticate_until_activation]
                elsif attempted_password_hash == current_auth[:password_hash]
                  # check if exceed max of devices authenticated
                  tokens = AuthenticableToken.where(:authenticable_id => current_auth[:id]) || []
                  tokens.each do |token|
                    token.destroy if Time.now > token[:remember_token_expires_at]
                  end
                  if tokens.count < @@max_device_authorized_allowed
                    # generate new remember token
                    result = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
                    # puts "set result=#{result}"
                    new_token = AuthenticableToken.new(:authenticable_id => current_auth[:id],
                      :remember_token => result,
                      :remember_token_begin_at => Time.now,
                      :remember_token_expires_at => Time.now + @@time_expiration_token)
                    new_token.save
                    current_auth[:remain_attempts_until_block] = @@max_attempted_login_failed
                    current_auth.save
                  else
                    # TODO:
                    # depends of max devices allowed policy must show message
                    # ¿delete all tokens?
                    # ¿delete older authentication?
                    # ¿only notice about situation?
                    raise RuntimeError, "exceed number of devices allowed"
                  end
                else
                  # decrement attmepts_failed
                  current_auth[:remain_attempts_until_block] =  current_auth[:remain_attempts_until_block]-1
                  if current_auth[:remain_attempts_until_block] < 1
                    current_auth[:block_until] = Time.now + Authenticable.time_disable_login_to_excced_max_login
                  end
                end
                  # save into db
                  current_auth.save
                  # user can be:
                  #   - nil
                  #   - block_until
                  #   - this time exceed 7 error trying login
              end
            end
            return result
          end

          # return remember_token if accepted or nil in other case
          # def self.authentication_by_password?(attempted_identifier, attempted_password)
          #   result = nil
          #   current_auth = Authenticable.find(:identifier => attempted_identifier)||{}
          #   attempted_password_hash = CrypterEngine.password_hash(attempted_password,current_auth[:password_salt])
          #   if attempted_password_hash == current_auth[:password_hash] and Authenticable.activation?(current_auth[:identifier]) and !Authentication.block?(current_auth[:identifier]) and !Authentication.reset_password?(current_auth[:identifier])
          #     # check if exceed max of devices authenticated
          #     if tokens.count < @@max_device_authorized_allowed
          #       destroy_token_authentication_expires_by_auth(current_auth[:id])
          #       result = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
          #       new_token = AuthenticableToken.new(:authenticable_id => current_auth[:id],
          #         :remember_token => result,
          #         :remember_token_begin_at => Time.now,
          #         :remember_token_expires_at => Time.now + @@time_expiration_token)
          #       new_token.save
          #       current_auth[:remain_attempts_until_block] = @@max_attempted_login_failed
          #       current_auth.save
          #     else
          #       raise MAX_DEVICES_ALLOW_EXCEED
          #     end
          #   elsif Authenticable.activation?(current_auth[:identifier]) and not Authentication.block?(current_auth[:identifier]) and not Authentication.reset_password?(current_auth[:identifier])
          #   # elsif Authenticable.activation?(current_auth[:identifier]) and !Authentication.block?(current_auth[:identifier]) and !Authentication.reset_password?(current_auth[:identifier])
          #     # decrease remain_attempts_until_block
          #     current_auth[:remain_attempts_until_block] =  current_auth[:remain_attempts_until_block]-1
          #     if current_auth[:remain_attempts_until_block] < 1
          #       current_auth[:block_until] = Time.now + Authenticable.time_disable_login_to_excced_max_login
          #     end
          #     current_auth.save
          #   else
          #   end
          #   return result
          # end

          def self.create_role(role_name)
            result = false
            role = Role.find(:name => role_name)
            unless role.nil?
              r = Role.new(:name => role_name, :status => 'enable')
              r.save
            end
            return result
          end

          def self.has_roles_by_identifier?(identifier,roles)
            #TODO: check authentication_token are in valid period???
            result = false
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              roles.each do |role|
                have_role = Role.join(:authenticable_roles, :role_id => :id ).where(:status => 'enable' ).where(:authenticable_id => current_auth[:id]).where(:name => role).count == 1 ? true : false ;
                result = (result or have_role) # one of role at least
              end
            else
              result = false
            end
            return result
          end

          def self.has_roles_by_token?(remember_token,roles)
              auth_token = AuthenticableToken.find(:remember_token => remember_token)
              current_auth = Authenticable.find(:id => auth_token[:authenticable_id])
              return self.has_roles_by_identifier?(current_auth[:identifier],roles)
          end

          def self.remember_tokens_by_identifier(identifier)
            result = []
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              tokens = AuthenticableToken.filter(:authenticable_id => current_auth[:id]) || {}
              tokens.each do |token|
                result << token[:remember_token]
              end
            end
            return result
          end

          ## return true if remember token are accepted or false in other case
          def self.authentication_by_remember_token?(attempted_remember_token,roles=nil)
            result = false
            token = AuthenticableToken.find(:remember_token => attempted_remember_token)
            unless token.nil?
              result = true if Time.now < token[:remember_token_expires_at]
              tokens = AuthenticableToken.find(:authenticable_id => token[:authenticable_id] )
            end
            return result
          end

          def self.archive_authentication(identifier,archived_reason=nil)
            result = false
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              # migration to AuthenticableArchived table
              auth_archived = AuthenticableArchive.new(:identifier => identifier,
                :archived_reason => archived_reason,
                :activation_at => current_auth[:activation_at],
                :created_at => current_auth[:activation_at],
                :updated_at => current_auth[:updated_at])
              auth_archived.save
              AuthenticableToken.filter(:authenticable_id => current_auth[:id]).delete
              AuthenticableRole.filter(:authenticable_id => current_auth[:id]).delete
              current_auth.destroy
              result = true
            end
          end

          private

          def destroy_token_authentication_expires_by_auth(auth_id)
            tokens = AuthenticableToken.where(:authenticable_id => auth_id) || []
            tokens.each do |token|
              token.destroy if Time.now > token[:remember_token_expires_at]
            end
          end

        end # class


      end #module PersistenceSequel
    end #module Helpers
  end #module AuthEngine
end #module Sinatra
