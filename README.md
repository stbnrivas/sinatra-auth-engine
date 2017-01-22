# Sinatra::AuthEngine

this gem is programmers friendly, or i will try. reduce configuration assuming that you like sequel the ruby database toolkit in the sinatra apps

The reason for the implementation of this gem is to honor J.M.R.N, from whom I could not learn all that he could teach me. Thanks you boss.

# By configuration annotations

configure: if user can be authenticate whitout account has been activated
configure: name of tables and fields into DB do named dinamically
configure: policy max device authenticated allowed:
    - allow and delete some other token
    - doesnt allow because exit in another device
    - show list of devices to select which un authorized
configure: if user without activation try authentication dont assume right behaviour
    - allow if configuration
    - disallow if configuration
configure: if user can change her identifier, this enable identifier_history field into db

# TODOING list


- to do connection_engine_sequel
    - migrating file engine.rb -> connection_engine_sequel.rb

    - at self.add_roles(remember_token, roles) allow or disallow current_user[:id]??

    - where fuck site the migration file for sequel ¿RakeFile? with a plain file for configuration where map the every attribute in every atttribute in database??? WTFB



# TODO list
- question? if you try add role by signup or add_roles_by_identifier never see an error even you give a non existing role_name, because the user should can signup without problems, is a problem of programmer

- how time block authentication after max fails authentication exceed??

- explain this gem use at sinatra:
  - classic style
  - modular style

- sinatra-auth-engine.gemspec

- clean migration  to add or remove

- to do, add support for multiples tokens authentication and numbers of tokens allowed

- to do flexible authenticable migration, you can add authentication:
    - to User model authentication
    - to documents files need has_role? to see or to be a Authenticable



- to do connection_engine_yml with multithread support
- in neither place constraint to Authenticable.identifier to be a email... think about maybe by configuration this can be done

- how fuck i test if i havent a database...

  o fixtures  

  o rakefile
    namespace :db do
      namespace :test do
        task :prepare => :environment do
            Rake::Task["db:seed"].invoke
        end
      end
    end

meditate shall we do...

- omni auth https://developer.github.com/guides/basics-of-authentication/

- can change the identifier of auth? only if the new don't exist already


- explain how to expand to another connections engines. only supported:
 - yml (quick and dirty that we loved)
 - sequel (the proffesional ruby database that we loved with multiples databases connections)


- now only one device have token_authenticacion if you login with another disconnect the another. Maybe expand to multiples tokens because one user have multiples devices...

- abstraction forget password not supported, is external to this library


- enable recovery by three answers ?


## Features





## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sinatra-auth-engine'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sinatra-auth-engine

## Usage

TODO: Write usage instructions here
