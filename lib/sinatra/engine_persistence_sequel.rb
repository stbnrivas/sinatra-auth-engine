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

        class AuthenticableUnsubscribe < Sequel::Model
        end

        class Authenticable < Sequel::Model

          @@max_attempted_login_failed = 7
          @@max_device_authorized_allowed = 5
          @@time_expiration_token = (2*7*24*60*60) # 2 Weeks
          @@password_reset_expires =  2*60*60 # 2 Hours
          @@time_disable_login_to_excced_max_login = 2*60*60 # 2 Hours

          def self.max_attempted_login_failed
            @@max_attempted_login_failed
          end

          def self.max_device_authorized_allowed
            @@max_device_authorized_allowed
          end
          # in this case sequel takes over attributtes map to database, powered by Jeremy Evans Thanks
          # attr_reader :index # database index autoincrement
          # attr_reader :identifier
          # attr_reader :password_salt
          # attr_reader :password_hash
          # attr_reader :attempts_failed
          # attr_reader :block_until
          # attr_reader :activation_code
          # attr_reader :activation_at
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
                :attempts_failed => @@max_attempted_login_failed,
                :activation_code => activation_code)
              new_authenticable.save
              # check if roles exist for add AuthenticableRole
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

          def self.activation_code(identifier)
            current_auth = Authenticable.find(:identifier => identifier)
            return current_auth[:activation_code] unless current_auth.nil?
          end

          def self.activation?(identifier)
            current_auth = Authenticable.find(:identifier => identifier)||{}
            current_auth[:activation_at].nil? ? false : true ;
          end


          def self.activate!(activation_code)
            result = false
            current_auth = Authenticable.find(:activation_code => activation_code)
            unless current_auth.nil?
              current_auth[:activation_at] = Time.now
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
              @@password_reset_expires_at = Time.now + (60*60*2) # two hours # TODO: move to configuration.
              result = true

              tokens = AuthenticableToken.find(:id => current_auth.id)
              tokens.each do |token|
                token.destroy
              end
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




            # return true when user has been activated by activation code send to email
            def self.active?(identifier)
              result = false
              u = Authenticable.find(:identifier => identifier)
              result = (not u[:activation_code].nil?) and  (not u[:activate_at].nil?)
            end


            # check is user is block by exceed @@max_attempted_login_failed times bad login
            def self.block?(identifier)
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
                u[:attempts_failed] = @@max_attempted_login_failed
                u[:block_until] = Time.now
                u.save
              end
            end



              ## return remember_token if accepted or nil in other case
              def self.authentication_by_password?(attempted_identifier, password)
                result = nil
                current_auth = Authenticable.find(:identifier => attempted_identifier)
                unless current_auth.nil?
                  if (current_auth[:block_until].nil?) or ( (Time.now > current_auth[:block_until]) and (current_auth[:attempts_failed] > 0) )

                    attempted_password_hash = CrypterEngine.password_hash(password,current_auth[:password_salt])
                    # confirm password and user has been activated
                    if current_auth[:activation_at].nil?
                      # if use do not been activated, and can not be authenticated
                      # TODO: user must be activate? or allow identify without
                    elsif attempted_password_hash == current_auth[:password_hash]
                      # check if exceed max of devices authenticated
                      tokens = AuthenticableToken.where(:authenticable_id => current_auth[:id]) || []
                      tokens.each do |token|
                        token.destroy if Time.now > token[:remember_token_expires_at]
                      end
                      if tokens.count < @@max_device_authorized_allowed
                        # generate new remember token
                        result = Array.new(25){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
                        new_token = AuthenticableToken.new(:authenticable_id => current_auth[:id],
                          :remember_token => result,
                          :remember_token_begin_at => Time.now,
                          :remember_token_expires_at => Time.now + @@time_expiration_token)
                        new_token.save
                        current_auth[:attempts_failed] = @@max_attempted_login_failed
                        current_auth.save
                      else
                        # TODO:
                        # depends of max devices allowed policy must show message
                      end
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
                # @@logger.debug("==== begin self.has_roles?")
                result = false
                current_auth = Authenticable.find(:identifier => identifier)
                unless current_auth.nil?
                  roles.each do |role|
                    have_role = Role.join(:authenticable_roles, :role_id => :id ).where(:status => 'enable' ).where(:authenticable_id => current_auth[:id]).where(:name => role).count == 1 ? true : false ;
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
                  auth_token = AuthenticableToken.find(:remember_token => remember_token)
                  current_auth = Authenticable.find(:id => auth_token[:authenticable_id])
                  return self.has_roles_by_identifier?(current_auth[:identifier],roles)
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

                def self.unsubscribe(identifier,description=nil)
                  result = false
                  current_auth = Authenticable.find(:identifier => identifier)
                  unless current_auth.nil?
                    # migration to AuthenticableUnsubscribes table
                    AuthenticableUnsubscribe.new(:identifier => identifier,
                    :unsubscribe_description => description,
                    :activation_at => current_auth[:activation_at],
                    :created_at => current_auth[:activation_at],
                    :updated_at => current_auth[:updated_at])
                    # delete Authenticable

                    tokens = AuthenticableToken.find(:authenticable_id => current_auth[:id])
                    tokens.destroy unless tokens.nil?
                    roles = AuthenticableRole.find(:authenticable_id => current_auth[:id])
                    roles.destroy unless roles.nil?
                    current_auth.destroy
                    result = true
                  end
                end

        end # class


      end #module PersistenceSequel
    end #module Helpers
  end #module AuthEngine
end #module Sinatra
