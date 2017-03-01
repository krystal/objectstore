module Atech
  # Global module, contains configuration information
  module ObjectStore
    ## Error class which all Object Store errors are inherited fro
    class Error < StandardError; end

    class << self
      # Hash to be passed to Mysql2::Client when creating a new client
      attr_accessor :backend_options

      # Largest file that can be uploaded to the database
      attr_accessor :maximum_file_size

      def maximum_file_size
        @maximum_file_size ||= 1024 * 1024 * 1024 # 1.megabyte
      end
    end
  end
end

require 'atech/object_store/connection'
require 'atech/object_store/file'
require 'atech/object_store/version'
