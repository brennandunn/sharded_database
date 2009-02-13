require 'lib/boot'
require 'lib/test_case'
require 'sharded_database'
require 'lib/models'

module ShardedDatabase
  class TestCase < Test::Unit::TestCase
    
    self.new_backtrace_silencer(:shoulda) { |line| line.include? 'lib/shoulda' }
    self.new_backtrace_silencer(:mocha) { |line| line.include? 'lib/mocha' }
    self.backtrace_silencers << :shoulda << :mocha
    

    def assert_releases_connection(klass, &block)
      original = klass.connection
      yield
      final = klass.connection
      assert_equal original, final
    end
    
  end
end

