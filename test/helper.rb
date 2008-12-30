require 'lib/boot'
require 'lib/test_case'
require 'sharded_database'
require 'lib/models'

module ShardedDatabase
  class TestCase < Test::Unit::TestCase
    
    self.new_backtrace_silencer(:shoulda) { |line| line.include? 'lib/shoulda' }
    self.new_backtrace_silencer(:mocha) { |line| line.include? 'lib/mocha' }
    self.backtrace_silencers << :shoulda << :mocha
    

    def assert_connection(configuration, *objects)
      expected_db = ::ActiveRecord::Base.configurations[configuration.to_s]['database']
      
      objects.each do |object|
        object_db   = object.respond_to?(:connection) ? object.connection.current_database : nil
        msg = "Expected #{object.inspect} to be connected to :#{expected_db}, but was :#{object_db}"
        assert_equal expected_db, object_db, msg
      end
    end
    
  end
end

