$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'atech/object_store/version'

Gem::Specification.new do |s|
  s.name = 'objectstore'
  s.version = Atech::ObjectStore::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A SQL based object store library"
  s.files = Dir["schema.sql", 'lib/atech/**/*.rb']
  s.require_path = 'lib'
  s.has_rdoc = false
  s.author = "Adam Cooke"
  s.email = "adam@atechmedia.com"
  s.homepage = "http://www.atechmedia.com"
  s.add_runtime_dependency "mysql2", '>= 0.3'
end
