require File.dirname(__FILE__) + '/../helper'

class AssociationTest < ShardedDatabase::TestCase
  
  def setup
    setup_environment
    @parent = AggregateEmployee.find_by_source('one')
  end
  
  context 'Connection delegation on has_many associations' do
    
    should 'fetch items from the parent instance connection' do
      assert ! @parent.items.empty?
      assert_connection :shard_one, @parent.items.first
    end
    
    should 'keep its connection when bubbling up to an associations parent' do
      assert_equal @parent, @parent.items.first.employee
    end
    
  end
  
  context '[UNFINISHED] Connection delegation on belongs_to associations' do
    
    should 'fetch the associated company for an employee from the respective connection' do
      assert_instance_of Company, @parent.company
    end
    
    should 'cache the associated object' do
      assert_equal @parent.company.object_id, @parent.company.object_id
    end
    
    should 'allow instance methods to the proxied object to access associations' do
      assert_equal @parent.company, @parent.call_company
    end
    
  end
  
end