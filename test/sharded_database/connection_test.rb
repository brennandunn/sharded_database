require File.dirname(__FILE__) + '/../helper'

class ConnectionTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  should 'foundationally support instances having a different connection than their parent class' do
    assert_not_equal AggregateEmployee.first.connection, AggregateEmployee.connection
  end
  
  should 'have instances of the same source share the same connection' do
    first, second = AggregateEmployee.find_all_by_source('two', :limit => 2)
    assert_equal first.connection.object_id, second.connection.object_id  # ensure that delegation is working correctly
  end
  
  should 'display instance connection when inspecting' do
    assert_match %{(Connection::One)}, AggregateEmployee.find_by_source('one').inspect
  end
  
  should 'return original connection after accessing just the target model' do
    original = Employee.connection
    AggregateEmployee.find_by_source('one')
    final = Employee.connection
    assert_equal original, final
  end
  
  context 'loading records when given a :connection key in the options hash' do
    
    should 'allow for an ActiveRecord::Base class to be supplied' do
      object = Employee.first(:connection => Connection::One)
    end
    
    should 'allow for a Proc object to be supplied' do
      proc = lambda { |*args| (args.first % 2) == 1 ? Connection::One : Connection::Two }
    end
    
  end
    
end