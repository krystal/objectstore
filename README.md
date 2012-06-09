# aTech Object Store

This tool allows you to easily create a MySQL-backed Object Store for storing file-based objects.
If you're setting up something replicated, you can set up MySQL Replication to automatically
replicate your data to other MySQL servers without any hassle.

It is designed for storing (very) small files (attachments, documents, images, avatars etc...) 
in a datastore which can easily be replicated to other environments.

## Background

* We want to be able to replicate small files from our application other servers.
* We want the backend system to be simple and easy to deploy.
* We don't want to store these files on our primary database server.
* We're not Facebook or Twitter.

## Installation

To get started, just add the following to your Gemfile.

```ruby
gem 'objectstore'
```

Once you have the gem installed, you will need to point it to a MySQL Client. This can be a clean
`Mysql2::Client` or something pooled if you're using this in a multi-threaded environment.

```ruby
require 'atech/object_store'
Atech::ObjectStore.backend = Mysql2::Client(:database => 'objectstore')
```

You will need to create a corresponding MySQL database using the included schema. The database is very
simple and just contains a table called `files` which contains your files and a small amount of
metadata.

```bash
mysql -p objectstore < schema.sql
```

## Usage Example

Let's imagine you've developed a e-mail platform and you need to store e-mail attachment files. You can
store these on your file system but you want to be able to easily replicate these to an offsite location
for DR purposes. 

Our primary database contains a table of attachments which include links back to their original e-mail but
also a key to identify the file in our object store. When the user requests the attachment, the application
will serve it from the data store by looking it up and then streaming it as appropriate (after running
various authorisation checks).

## Usage

The following information shows how to carry out a number of tasks using the library. All files which are added
to the datastore are addressed using a sequential numeric ID.

### The `Atech::ObjectStore::File` object

When looking up files or adding them to the datastore, you will be provided with an instance of this object.
This object allows you to access the file, metadata as well as manipulate the file as necessary.

#### Accessing Metadata on the object

```ruby
file.name       #=> the filename (for example 'my-filename.txt') as a string
file.size       #=> the size of the file in bytes as an integer
file.blob       #=> the content
file.created_at #=> the time the file was created as a Time object
file.updated_at #=> the time the file was last updated as a Time object
```
#### Looking up a an existing file

If you know the ID of a file you wish to lookup, use the method to return an appropriate object. If the file
does not exist, the `FileNotFound` exception will be raised.

```ruby
file = Atech::ObjectStore::File.find_by_id(123)
```

#### Adding a new file to the datastore

If you have some data and wish to add this to your datastore, you can use the `add_file` method and pass the
filename as well as the data you wish to store.

```ruby
file = Atech::ObjectStore::File.add_file('my-filename.txt', 'Hello World')
file.id   #=> 124
```

#### Uploading an existing local file into the datastore

You can use the library to upload files from your existing system by passing the path to the file you
wish to upload. This will return a file object,

```ruby
file = Atech::ObjectStore::File.add_file('path/to/new-file.txt')
```

#### Renaming a file

If you wish to change the name of a file which already exists, you can use the `rename` method, for example:

```ruby
file.rename('my-new-filename.txt')
```

#### Appending data to an existing file

If you'd like to add additional data to the end of an existing file, you can do so with the `append` method,
for example:

```ruby
file.data     #=> "ABC"
file.size     #=> 3
file.append('DEF')
file.data     #=> "ABCDEF"
file.size     #=> 6
```

#### Overwriting data for an existing file

If you'd like to overwrite the data stored for an existing file you can use the `overwrite` method, for example:

```ruby
file.data     #=> "ABC"
file.overwrite("DEF")
file.data     #=> "DEF"
```

#### Deleting a file

If you no longer wish to store a file which exists in the datastore, just use the `delete` method, for example:

```ruby
file.delete
```

Once you have deleted a file, you will not be able to make any changes to the file. If you attempt to use any
modification method, you will receive a `CannotEditFrozenFile` method.

#### Copying a file from the datastore to your local disk

If you'd like to copy a file from your datastore to your local disk, you can use the `copy` method, for example:

```ruby
file.data                               #=> "Hello World!"
file.size                               #=> 12
file.copy('path/to/my/localfile.txt')
# Look at the local file
File.read('path/to/my/localfile.txt')   #=> "Hello World!"
File.size('path/to/my/localfile.txt')   #=> 12
```
