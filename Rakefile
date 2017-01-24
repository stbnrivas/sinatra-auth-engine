require "sequel"
require "rake/testtask"

Rake::TestTask.new do |t|
  `[ -e db/testing.sqlite ] && rm db/testing.sqlite`
  Sequel.extension :migration
  DB = Sequel.connect('sqlite://db/testing.sqlite')
  Sequel::Migrator.run(DB, "db/migrations")
  t.libs << "test"
  # t.test_files = FileList['test/*_test.rb']
  t.test_files = FileList[
    'test/auth_engine_persistence_sequel_without_roles_test.rb',
    'test/auth_engine_persistence_sequel_with_roles_test.rb']
  # `[ -e db/testing.sqlite ] && rm db/testing.sqlite`
  # TODO: fails when remove db/testing.sqlite by above line
end
