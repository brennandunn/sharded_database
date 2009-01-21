require File.dirname(__FILE__) + '/../helper'

class ConnectionTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  should 'foundationally support instances having a different connection than their parent class' do
    assert_not_equal AggregateEmployee.first.connection, AggregateEmployee.connection
  end
  
  should 'have instances of the same source share the same connection' do
    first, second = AggregateEmployee.find_all_by_source('two', :limit => 2)
    
    assert_connection :shard_two, first, second
    assert_equal first.connection.object_id, second.connection.object_id  # ensure that delegation is working correctly
  end
  
  should 'display instance connection when inspecting' do
    assert_match %{(Connection::One)}, AggregateEmployee.find_by_source('one').inspect
  end
    
end