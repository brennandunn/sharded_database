require File.dirname(__FILE__) + '/../helper'

class ConnectionTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  should 'foundationally support instances having a different connection than their parent class' do
    assert_not_equal AggregateEstimate.first.connection, AggregateEstimate.connection
  end
  
  should 'have instances of the same source share the same connection' do
    first, second = AggregateEstimate.find_all_by_source('two', :limit => 2)
    
    assert_connection :shard_two, first, second
    assert_equal first.connection.object_id, second.connection.object_id  # ensure that delegation is working correctly
  end
  
  should 'display instance connection when inspecting' do
    assert_match %{(Connection::One)}, AggregateEstimate.find_by_source('one').inspect
  end
    
end