require File.dirname(__FILE__) + '/../helper'

class AssociationTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  context 'Connection delegation on has_many associations' do
    
    setup do
      @parent = AggregateEstimate.find_by_source('one')
    end
    
    should 'fetch items from the parent instance connection' do
      assert ! @parent.items.empty?
      assert_connection :one_db, @parent.items.first
    end
    
    should 'keep its connection when bubbling up to an associations parent' do
      assert_equal @parent, @parent.items.first.estimate
    end
    
  end
  
end