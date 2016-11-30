

module Sinatra
  module AuthEngine
    module Helpers
      module PersistenceSequel


        # TODO list
        # - when detect into db more than MAX_ATTTEMPTED_LOGIN_FAILED reset
        # - when user reset password all tokens_authentication must be deleted
        # - when resend token of activation send diferent every time
        # - when send token of password send diferent every time

        # persistence with sequel
        require 'sequel'



        MAX_ATTTEMPTED_LOGIN_FAILED = 7
        MAX_TOKEN_AUTHORIZED_ALLOWED = 5
        TIME_EXPIRATION_TOKEN = (2*7*24*60*60) # 2 Weeks
        PASSWORD_RESET_EXPIRES = 2*60*60 # 2 Hours


        class Roles < Sequel::Model
          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :name
        end


        class AuthenticableRoles < Sequel::Model
          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :identifier_authenticable
          # attr_reader :role_name
        end

        class AuthenticableTokens < Sequel::Model
          # id
          # authenticable_id
          # remember_token
          # remember_token_begin_at
          # remember_token_expires_at
          # created_at
          # updated_at
        end

        class Authenticable < Sequel::Model

          # MAX_ATTTEMPTED_LOGIN_FAILED = 7

          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :index # database index autoincrement
          # attr_reader :identifier
          # attr_reader :password_salt
          # attr_reader :password_hash
          # attr_reader :attempts_failed
          # attr_reader :block_until
          # attr_reader :activation_code
          # attr_reader :activated_at
          # attr_reader :password_reset_token
          # attr_reader :password_reset_token_expires_at

          def self.signup(identifier, password, roles=nil)
            result = nil
            # check if exist
            current_auth = Authenticable.find(:identifier => identifier)
            if current_auth.nil?
              password_salt = CrypterEngine.generate_salt
              password_hash = CrypterEngine.password_hash( password, password_salt)
              activation_code = Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
              new_authenticable = Authenticable.new( :identifier => identifier,
                :password_hash => password_hash,
                :password_salt => password_salt,
                :attempts_failed => MAX_ATTTEMPTED_LOGIN_FAILED,
                :activation_code => activation_code)
              new_authenticable.save
              # check if roles exist for add AuthenticableRoles
              unless roles.nil?
                self.add_roles_by_identifier(identifier,roles)
              end
              result = true
            else # exist, then check password
              if self.authentication_by_password?(identifier, password)
                unless roles.nil?
                  # if password right then add roles if doesnt exists now
                  self.add_roles_by_identifier(identifier, roles)
                end
              end
              result = true
            end
            return result
          end


          def self.activate!(activation_code)
            result = false
            current_auth = Authenticable.find(:activation_code => activation_code)
            unless current_auth.nil?
              current_auth[:activated_at] = Time.now
              current_auth.save
              result = true
            end
            return result
          end


          def self.reset_password!(attempted_identifier)
            result = false
            current_auth = Authenticable.find(:identifier => attempted_identifier)
            unless current_auth.nil?
              password_reset_token = Array.new(30){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
              password_reset_expires_at = Time.now + (60*60*2) # two hours # TODO: move to configuration.
              result = true
            end
            return result
          end


          def self.new_password(password_reset_token,new_password)
            result = false
            current_auth = Authenticable.find(:password_reset_token => password_reset_token)
            if not current_auth.nil? and current_auth[:remember_token_expires_at] < Time.now
              # TODO  CrypterEngine.generate_salt
              #password_salt = BCrypt::Engine.generate_salt
              password_salt = CrypterEngine.generate_salt
              # TODO  CrypterEngine.password_hash(new_password,password_salt)
              #password_hash = BCrypt::Engine.hash_secret(new_password, password_salt)
              password_hash = CrypterEngine.password_hash(new_password,password_salt)

              current_auth[:password_salt] = password_salt
              current_auth[:password_hash] = password_hash
              current_auth.save
              result = true
            end
            return result
          end

          def self.add_roles_by_identifier(identifier, roles)
            current_auth = Authenticable.find(:identifier => identifier)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Roles.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRoles.find(:authenticable_id => current_auth[:id], :role_id => current_role[:id])
                  if ur.nil?
                    # TODO: think about current_auth[:id]
                    ur = AuthenticableRoles.new(:authenticable_id => current_auth[:id], :role_id => current_role[:id],:status => 'enable')
                    ur.save
                  end
                end
              end
            end
            raise NotImplementedYet
          end


          def self.add_roles_by_remember_token(remember_token, roles)
            #current_auth = Authenticable.find(:remember_token => remember_token)
            auth_token = AuthenticableTokens.find(:remember_token => remember_token)
            current_auth = Authenticable.find(:id => auth_token[:id])
            self.add_roles_by_identifier(current_auth[:identifier],roles)
          end


          def self.remove_roles(remember_token,roles)
            current_auth = Authenticable.find(:remember_token => remember_token)
            unless current_auth.nil?
              roles.each do |role|
                current_role = Roles.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRoles.find(:authenticable_id => current_auth[:id], :role_id => current_role[:id])
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
                current_role = Roles.find(:name => role)
                unless current_role.nil?
                  # TODO: think about current_auth[:id]
                  ur = AuthenticableRoles.find(:user_id => current_auth[:id], :role_id => current_role[:id])
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
                current_role = Roles.find(:name => role)
                unless current_role.nil?
                  ur = AuthenticableRoles.find(:user_id => current_auth[:id], :role_id => current_role[:id])
                  unless ur.nil?
                    ur[:status] = 'enable'
                    ur.save
                  end
                end
              end
            end
          end




            # return true when user has been activated by activation code send to email
            def self.actived?(identifier)
              result = false
              u = Authenticable.find(:identifier => identifier)
              result = (not u[:activation_code].nil?) and  (not u[:activate_at].nil?)
            end


            # check is user is block by exceed MAX_ATTTEMPTED_LOGIN_FAILED times bad login
            def self.blocked?(identifier)
              result = false
              u = Authenticable.find(:identifier => identifier)
              unless u[:block_until].nil? and u[:attempts_failed]<1
                result = true
              end
              return result
            end

            # unblock the user access
            def self.unblock!(identifier)
              u = Authenticable.find(:identifier => identifier)
              unless u.nil?
                u[:attempts_failed] = MAX_ATTTEMPTED_LOGIN_FAILED
                u[:block_until] = Time.now
                u.save
              end
            end



              ## return remember_token if accepted or nil in other case
              def self.authentication_by_password?(attempted_identifier, password)
                result = nil
                # search into db
                current_auth = Authenticable.find(:identifier => attempted_identifier)

                # " current_auth.nil? #{current_auth.nil?} <br> "
                # " current_auth[:block_until] #{current_auth[:block_until]}"

                unless current_auth.nil?
                  if (current_auth[:block_until].nil?) or ( (Time.now > current_auth[:block_until]) and (current_auth[:attempts_failed] > 0) )

                    # TODO change for crypt_engine
                    # attempted_password_hash = BCrypt::Engine.hash_secret(attempted_password, current_auth[:password_salt])
                    attempted_password_hash = CrypterEngine.password_hash(password,current_auth[:password_salt])
                    # confirm password and user has been activated
                    if current_auth[:activated_at].nil?
                      # if use do not been activated

                    elsif attempted_password_hash == current_auth[:password_hash]
                      # generate new remember token
                      result = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
                      current_auth[:remember_token] = result
                      # generate new remember token expire at
                      current_auth[:remember_token_expires_at] = Time.now + (60*60*24*7) # 1.week
                      current_auth[:attempts_failed] = 7
                      current_auth[:block_until] = nil
                    else
                      # decrement attmepts_failed
                      current_auth[:attempts_failed] =  current_auth[:attempts_failed] - 1
                      if current_auth[:attempts_failed] < 1
                        current_auth[:block_until] = Time.now + (60*60) # 1 hour until next login
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


              def self.has_roles_by_identifier?(identifier,roles)
                #TODO: check authentication_token are in valid period???
                # @@logger.debug("==== begin self.has_roles?")
                result = false
                current_auth = Authenticable.find(:identifier => identifier)
                unless current_auth.nil?
                  roles.each do |role|
                    have_role = Roles.join(:authenticable_roles, :role_id => :id ).where(:status => 'enable' ).where(:authenticable_id => current_auth[:id]).where(:name => role).count == 1 ? true : false ;
                    # @@logger.debug("#{role} have_role #{have_role} ")
                    # @@logger.debug("result(#{result}) and have_role(#{have_role}) = #{result and have_role} ")
                    result = (result or have_role) # one of role at least
                  end
                else
                  result = false
                end
                # @@logger.debug("result #{result}")
                # @@logger.debug("==== end  self.has_roles?")
                return result
              end

              def self.has_roles_by_token?(remember_token,roles)
                  auth_token = AuthenticableTokens.find(:remember_token => remember_token)
                  current_auth = Authenticable.find(:id => auth_token[:authenticable_id])
                  return self.has_roles_by_identifier?(current_auth[:identifier],roles)
              end



                ## return true if remember token are accepted or false in other case
                def self.authentication_by_remember_token?(attempted_remember_token,roles=nil)
                  puts attempted_remember_token
                  result = false
                  current_user = Authenticable.find(:remember_token => attempted_remember_token)
                  unless current_user.nil? and current_user[:remember_token_expires_at].nil?
                    if not (current_user[:remember_token_expires_at].nil?) and Time.now < current_user[:remember_token_expires_at]
                      unless roles.nil?
                        result = self.has_roles?(attempted_remember_token,roles)
                      else
                        result = true #FROM HERE
                      end
                    end
                  end
                  return result
                end

        end # class


      end
    end
  end
end
