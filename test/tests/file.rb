require 'test_helper'
require 'fileutils'

class TestFile < Test::Unit::TestCase
  
  def test_adding_files
    file = Atech::ObjectStore::File.add_file("test1.txt", "Hello World!")
    assert file.is_a?(Atech::ObjectStore::File)
    assert file.id.is_a?(Integer)
  end
  
  def test_adding_files_without_filenames
    assert_raise(Atech::ObjectStore::File::ValidationError) { Atech::ObjectStore::File.add_file(nil, "Hello")}
  end

  def test_adding_empty_files
    file = Atech::ObjectStore::File.add_file('empty-file.txt')
    assert file.is_a?(Atech::ObjectStore::File)
    assert_equal 0, file.size
    assert_equal '', file.blob
  end
  
  def test_retriving_files
    file = Atech::ObjectStore::File.add_file("test2.txt", "Hello World!")
    retreived_file = Atech::ObjectStore::File.find_by_id(file.id)
    assert retreived_file.is_a?(Atech::ObjectStore::File)
    assert_equal "test2.txt", retreived_file.name
    assert_equal "Hello World!", retreived_file.blob
    assert_equal 12, retreived_file.size
  end
  
  def test_retriving_files_which_dont_exist
    assert_raise(Atech::ObjectStore::File::FileNotFound) { Atech::ObjectStore::File.find_by_id(1000000)}
  end
  
  def test_uploading_files
    path_to_test_file = File.expand_path('../../fixtures/example1.pdf', __FILE__)
    uploaded_file = Atech::ObjectStore::File.add_local_file(path_to_test_file)
    assert uploaded_file.is_a?(Atech::ObjectStore::File)
    assert_equal 'example1.pdf', uploaded_file.name
    assert_equal File.size(path_to_test_file), uploaded_file.size
    assert_equal File.read(path_to_test_file), uploaded_file.blob
    assert_equal File.stat(path_to_test_file).ctime.utc, uploaded_file.created_at
    assert_equal File.stat(path_to_test_file).mtime.utc, uploaded_file.updated_at
  end
  
  def test_uploading_files_where_file_does_not_exist
    assert_raise Atech::ObjectStore::File::ValidationError do
      Atech::ObjectStore::File.add_local_file(File.expand_path('../../fixtures/invalid_file.pdf', __FILE__))
    end
  end
  
  def test_renaming_files
    file = Atech::ObjectStore::File.add_file("rename_test1.txt", "Hello!")
    assert_equal "rename_test1.txt", file.name
    new_name = "rename_test2.txt"
    file.rename(new_name)
    assert_equal new_name, file.name
  end
  
  def test_deleting_files
    file = Atech::ObjectStore::File.add_file("delete_test.txt", "I will be deleted in a moment")
    assert file.is_a?(Atech::ObjectStore::File)
    file.delete
    assert_raise Atech::ObjectStore::File::FileNotFound do
      Atech::ObjectStore::File.find_by_id(file.id)
    end
  end
  
  def test_deletion_locking
    file = Atech::ObjectStore::File.add_file("delete_test.txt", "I will be deleted in a moment")
    file.delete
    assert file.frozen?
    assert_raise(Atech::ObjectStore::File::CannotEditFrozenFile) { file.append('Hello') }
    assert_raise(Atech::ObjectStore::File::CannotEditFrozenFile) { file.rename('newname.txt') }
    assert_raise(Atech::ObjectStore::File::CannotEditFrozenFile) { file.overwrite('Hello') }
    assert_raise(Atech::ObjectStore::File::CannotEditFrozenFile) { file.delete }
  end
  
  def test_overwriting_files
    initial_content = "Initial text!"
    overwrite_text = "Some other text which is much longer!"
    file = Atech::ObjectStore::File.add_file("overwrite_test.txt", initial_content)
    assert_equal initial_content, file.blob
    assert_equal initial_content.bytesize, file.size
    file.overwrite(overwrite_text)
    assert_equal overwrite_text, file.blob
    assert_equal overwrite_text.bytesize, file.size
  end
  
  def test_appending_to_files
    initial_content = 'ABC'
    extra_content = 'DEF'
    file = Atech::ObjectStore::File.add_file("append_test.txt", initial_content)
    assert_equal initial_content, file.blob
    file.append('DEF')
    assert_equal initial_content + extra_content, file.blob
    assert_equal initial_content.bytesize + extra_content.bytesize, file.size
  end
  
  def test_copying_to_local
    new_file_content = "I am going to be copied to the local file system!"
    local_path = File.join('', 'tmp', 'objectstore-local-file')
    FileUtils.rm_f(local_path)
    new_file = Atech::ObjectStore::File.add_file("copy_test.txt", new_file_content)
    assert !File.exist?(local_path)
    new_file.copy(local_path)
    assert File.exist?(local_path)
    assert_equal File.read(local_path), new_file.blob
    assert_equal File.size(local_path), new_file.size
  end
  
end