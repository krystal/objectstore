require 'test/unit'
require 'mysql2'
require 'atech/object_store'

## Establish a database connection
Atech::ObjectStore.backend = Mysql2::Client.new(:host => 'localhost', :username => 'root', :database => 'objectstore_test')

## Empty the files table so we can start with a clean slate
Atech::ObjectStore.backend.query("TRUNCATE `files`")
