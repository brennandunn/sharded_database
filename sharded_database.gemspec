Gem::Specification.new do |s|
  s.name     = "sharded_database"
  s.version  = "0.3.3"
  s.date     = "2009-02-12"
  s.summary  = "Allows for connection handling at the instance level."
  s.email    = "me@brennandunn.com"
  s.homepage = "http://github.com/brennandunn/sharded_database/"
  s.description = "Allows for connection handling at the instance level."
  s.has_rdoc = true
  s.authors  = ["Brennan Dunn"]
  s.files    = [
    "Rakefile",
    "README.rdoc",
    "init.rb",
    "lib/sharded_database.rb",
    "lib/sharded_database/aggregate.rb",
    "lib/sharded_database/aggregate_proxy.rb",
    "lib/sharded_database/core_extensions.rb", 
    "lib/sharded_database/model_with_connection.rb", 
    "lib/sharded_database/has_many_association.rb" ]
  s.test_files = [
    "test/helper.rb",
    "test/sharded_database/association_test.rb",
    "test/sharded_database/connection_test.rb",
    "test/sharded_database/instance_test.rb",
    "test/lib/boot.rb",
    "test/lib/database.yml",
    "test/lib/models.rb",
    "test/lib/test_case.rb" ]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ["README.rdoc"]
end