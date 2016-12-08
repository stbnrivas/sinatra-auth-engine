require "sequel"


namespace :test do

  desc "build database for execute the test"
  # `rm db/test.sqlite`
  task "run" do
    # `rm db/test.sqlite; sequel -m db/migrations sqlite://db/test.sqlite`
    # `ruby test/auth_engine_persistence_sequel_test.rb`

    # rm db/test.sqlite; sequel -m db/migrations sqlite://db/test.sqlite; ruby test/auth_engine_persistence_sequel_test.rb
    # ruby test/auth_engine_persistence_sequel_test.rb

    `sequel -m db/migrations sqlite://db/test.sqlite`
    `ruby test/auth_engine_persistence_sequel_test`
    # `rm db/test.sqlite`
  end


end
