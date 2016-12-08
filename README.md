# Sinatra::AuthEngine

this gem is programmers friendly, or i will try. reduce configuration assuming that you like sequel the ruby database toolkit in the sinatra apps

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

# TODOING list


- to do connection_engine_sequel
    - migrating file engine.rb -> connection_engine_sequel.rb
==>
    - at self.add_roles(remember_token, roles) allow or disallow current_user[:id]??

    - where fuck site the migration file for sequel ¿RakeFile? with a plain file for configuration where map the every attribute in every atttribute in database??? WTFB



# TODO list

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

## Description

I am always always always including authentication code, never agai. DRY, in honor of my master sith I build my own authentication framework for Sinatra. With all knowledge of my master Jose Ruiz.

You must be first Warden o Rodauth a very professional solution

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

some like:

    register::sinatra-auth-engine

    require 'sinatra'
    require 'sinatra/auth/engine/'

    get "/hello" do
      h "1 < 2"     # => "1 &lt; 2"
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO: in implementation

dinamically selection of attributes a

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sinatra-auth-engine. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
