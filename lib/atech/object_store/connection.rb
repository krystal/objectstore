module Atech
  module ObjectStore
    # A very simple connection pool. Allows as many connections as MySQL is happy to give us. Probably not
    # compatible with a truly concurrent Ruby due to the use of Array#shift, but good enough for MRI
    module Connection
      @free_clients = []

      # Get an available connection (or create a new one) and yield it to the passed block. Places the client into
      # @free_clients once done.
      #
      # @yield [client] Block that wishes to access database
      # @yieldparam [Mysql2::Client] client A mysql2 client just for this block
      #
      # @return [Object] Result of the block
      def self.client
        client = @free_clients.shift || new_client
        return_value = nil
        tries = 2
        begin
          return_value = yield client
        rescue Mysql2::Error => e
          if e.message =~ /(lost connection|gone away)/i && (tries -= 1) > 0
            retry
          else
            raise
          end
        ensure
          @free_clients << client
        end
        return_value
      end

      private

      # Build a new Mysql2 client with the options suppplied in backend_options
      #
      # @return [Mysql2::Client] Fresh mysql2 client
      def self.new_client
        Mysql2::Client.new(Atech::ObjectStore.backend_options)
      end
    end
  end
end
