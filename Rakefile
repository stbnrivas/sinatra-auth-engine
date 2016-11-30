require "bundler/gem_tasks"
require "rspec/core/rake_task"

# require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec


namespace :test do

  desc "build database for execute the test"
  task "prepare" do
    require 'sequel'
    puts `sequel -m db/migrations sqlite://test.sqlite`
    `mv test.sqlite ./db/`
  end



# Rake::TestTask.new do |t|
#   t.libs.push "lib"
#   t.test_files = FileList['test/*_test.rb']
#   t.verbose = true
# end

  desc "execute test with database before built"
  task "execute" do
    # Sequel::Model.plugin(:schema)
    # DB = Sequel.connect('sqlite://db/discover.sqlite')
  end

  desc "clean database of test"
  task "clean" do

    `rm ./db/test.sqlite`
  end

  desc "full test execution"
  task "run-test" => [:prepare, :execute, :clean] do

  end

end
