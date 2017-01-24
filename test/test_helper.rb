
path = File.expand_path(File.join(File.dirname(__FILE__), "../lib"))
$:.unshift(path) unless $:.include?(path)

# DB = Sequel.connect(:adapter => :sqlite, :database => 'file::memory:?cache=shared')
DB = Sequel.connect(:adapter => :sqlite, :database => 'db/testing.sqlite')
