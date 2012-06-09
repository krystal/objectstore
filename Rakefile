task :default do
  $:.unshift(File.expand_path('../lib', __FILE__))
  $:.unshift(File.expand_path('../test', __FILE__))
  Dir[File.expand_path('../test/tests/*.rb', __FILE__)].each do |test|
    require test
  end
end