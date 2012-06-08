require 'mysql2'

module Atech
  module ObjectStore
    VERSION = '0.0.1'
    
    ## Error class which all Object Store errors are inherited fro
    class Error < StandardError; end
    
    class << self
      attr_accessor :mysql
    end
    
  end
end

require 'atech/object_store/file'
