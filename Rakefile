require "sequel"
require "rake/testtask"


namespace :test_old do

  desc "build database for execute the test"
  # `rm db/test.sqlite`
  task "run" do
    # `rm db/test.sqlite; sequel -m db/migrations sqlite://db/test.sqlite`
    # `ruby test/auth_engine_persistence_sequel_test.rb`

    # rm db/test.sqlite; sequel -m db/migrations sqlite://db/test.sqlite; ruby test/auth_engine_persistence_sequel_test.rb
    # ruby test/auth_engine_persistence_sequel_test.rb


    `sequel -m db/migrations sqlite://db/test.sqlite`
    `ruby test/auth_engine_persistence_sequel_without_roles_test.rb`

    # it doesnt work, try:
    # =>  ruby test/auth_engine_persistence_sequel_without_roles_test.rb
    # `ruby test/auth_engine_persistence_sequel_without_roles_test`
    # `ruby test/auth_engine_persistence_sequel_with_roles_test`
    # `rm db/test.sqlite`
  end

end





  Rake::TestTask.new do |t|
    # `sequel -m db/migrations sqlite://db/test.sqlite`
    t.test_files = FileList['test/*_test.rb']
    # `rm db/test.sqlite`
  end
  #desc "Run tests"

  # task default: :test
