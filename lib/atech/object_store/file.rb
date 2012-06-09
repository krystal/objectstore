module Atech
  module ObjectStore
    class File
      
      ## Raised when a file cannot be found
      class FileNotFound < Error; end
      
      ## Raised if a file cannot be added
      class ValidationError < Error; end
      
      ## Raised if a frozen file is editted
      class CannotEditFrozenFile < Error; end
      
      ## Returns a new file object for the given ID. If no file is found a FileNotFound exception will be raised
      ## otherwise the File object will be returned.
      def self.find_by_id(id)
        result = ObjectStore.backend.query("SELECT * FROM files WHERE id = #{id.to_i}").first || raise(FileNotFound, "File not found with id '#{id.to_i}'")
        self.new(result)
      end
      
      ## Imports a new file by passing a path and returning a new File object once it has been added to the database.
      ## If the file does not exist a ValidationError will be raised.
      def self.add_local_file(path)
        if ::File.exist?(path)
          file_stat = ::File.stat(path)
          file_data = ::File.read(path)
          file_name = path.split('/').last
          add_file(file_name, file_data, :created_at => file_stat.ctime, :updated_at => file_stat.mtime)
        else
          raise ValidationError, "File does not exist at '#{path}' to add"
        end
      end
      
      ## Inserts a new File into the database. Returns a new object if successfully inserted or raises an error.
      ## Filename & data must be provided, options options will be added automatically unless specified.
      def self.add_file(filename, data = '', options = {})
        ## Create a hash of properties to be for this class
        options[:name]          = filename
        options[:size]        ||= data.bytesize
        options[:blob]          = data
        options[:created_at]  ||= Time.now
        options[:updated_at]  ||= Time.now
        
        ## Ensure that new files have a filename & data
        raise ValidationError, "A 'name' must be provided to add a new file" if options[:name].nil?
        
        ## Encode timestamps
        options[:created_at] = options[:created_at].utc
        options[:updated_at] = options[:updated_at].utc
        
        ##Create an insert query
        columns = options.keys.join('`,`')
        data    = options.values.map { |data| escape_and_quote(data.to_s) }.join(',')
        ObjectStore.backend.query("INSERT INTO files (`#{columns}`) VALUES (#{data})")

        ## Return a new File object
        self.new(options.merge({:id => ObjectStore.backend.last_id}))
      end
      
      ## Initialises a new File object with the hash of attributes from a MySQL query ensuring that
      ## all symbols are strings
      def initialize(attributes)
        @attributes = parsed_attributes(attributes)
      end
      
      ## Returns details about the file
      def inspect
        "#<Atech::ObjectStore::File[#{id}] name=#{name}>"
      end
      
      ## Returns the ID of the file
      def id
        @attributes['id']
      end
      
      ## Returns the name of the file
      def name
        @attributes['name']
      end
      
      ## Returns the size of the file as an integer
      def size
        @attributes['size'].to_i
      end
      
      ## Returns the date the file was created
      def created_at
        @attributes['created_at']
      end
      
      ## Returns the date the file was last updated
      def updated_at
        @attributes['updated_at']
      end
      
      ## Returns the blob data
      def blob
        @attributes['blob']
      end
      
      ## Returns whether this objec tis frozen or not
      def frozen?
        !!@frozen
      end
      
      ## Downloads the current file to a path on your local server. If a file already exists at
      ## the path entered, it will be overriden.
      def copy(path)
        ::File.open(path, 'w') { |f| f.write(blob) }
      end
      
      ## Appends data to the end of the current blob and updates the size and update time as appropriate.
      def append(data)
        raise CannotEditFrozenFile, "This file has been frozen and cannot be appended to" if frozen?
        ObjectStore.backend.query("UPDATE files SET `blob` = CONCAT(`blob`, #{self.class.escape_and_quote(data)}), `size` = `size` + #{data.bytesize}, `updated_at` = '#{self.class.time_now}' WHERE id = #{@attributes['id']}")
        reload(true)
      end
      
      ## Overwrites any data which is stored in the file
      def overwrite(data)
        raise CannotEditFrozenFile, "This file has been frozen and cannot be overwriten" if frozen?
        ObjectStore.backend.query("UPDATE files SET `blob` = #{self.class.escape_and_quote(data)}, `size` = #{data.bytesize}, `updated_at` = '#{self.class.time_now}' WHERE id = #{@attributes['id']}")
        @attributes['blob'] = data
        reload
      end
      
      ## Changes the name for a file
      def rename(name)
        raise CannotEditFrozenFile, "This file has been frozen and cannot be renamed" if frozen?
        ObjectStore.backend.query("UPDATE files SET `name` = #{self.class.escape_and_quote(name)}, `updated_at` = '#{self.class.time_now}' WHERE id = #{@attributes['id']}")
        reload
      end
      
      ## Removes the file from the database
      def delete
        raise CannotEditFrozenFile, "This file has been frozen and cannot be deleted" if frozen?
        ObjectStore.backend.query("DELETE FROM files WHERE id = #{@attributes['id']}")
        @frozen = true
      end
      
      ## Reload properties from the database. Optionally, pass true to include the blob
      ## in the update
      def reload(include_blob = false)
        query = ObjectStore.backend.query("SELECT #{include_blob ? '*' : '`id`, `name`, `size`, `created_at`, `updated_at`'} FROM files WHERE id = #{@attributes['id']}").first
        @attributes.merge!(parsed_attributes(query))
      end
            
      private
      
      def parsed_attributes(attributes)
        attributes.inject(Hash.new) do |hash,(key,value)|
          hash[key.to_s] = value
          hash
        end
      end
      
      def self.escape_and_quote(string)
        string = string.strftime('%Y-%m-%d %H:%M:%S') if string.is_a?(Time)
        "'#{ObjectStore.backend.escape(string)}'"
      end
      
      def self.time_now
        Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
      end
      
      
    end
  end
end
