module Atech
  module ObjectStore
    VERSION = '1.1.0'
    
    ## Error class which all Object Store errors are inherited fro
    class Error < StandardError; end
    
    class << self
      attr_accessor :backend
      attr_accessor :maximum_file_size
      
      def maximum_file_size
        @maximum_file_size ||= 1024 * 1024 * 1024
      end
      
    end
    
  end
end

require 'atech/object_store/file'
