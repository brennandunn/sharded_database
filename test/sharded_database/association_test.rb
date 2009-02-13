require File.dirname(__FILE__) + '/../helper'

class AssociationTest < ShardedDatabase::TestCase
  
  def setup
    setup_environment
    @parent = AggregateEmployee.find_by_source('one')
  end
  
  context 'Connection delegation on has_many associations' do
    
    should 'fetch items from the parent instance connection' do
      assert_instance_of Array, @parent.items
      assert_equal 1, @parent.items.size
    end
    
    should 'return original connection after accessing a has_many association' do
      assert_releases_connection(Item) do
        AggregateEmployee.find_by_source('one').items
      end
    end
    
    should 'be able to add objects to a collection association' do
      item = @parent.items.create :name => 'Test create'
      assert @parent.items(true).include?(item)
    end

    should 'be able to delete objects in a collection association' do
      @parent.items.first.destroy
      assert @parent.items(true).empty?
    end

    should 'be able to read/write item ids' do
      ids = @parent.items.map(&:id)
      assert_equal ids, @parent.item_ids
    end

  end
  
  context 'Connection delegation on belongs_to associations' do
    
    should 'fetch the associated company for an employee from the respective connection' do
      assert_instance_of Company, @parent.company
    end
    
    should 'cache the associated object' do
      assert_equal @parent.company.object_id, @parent.company.object_id
    end
    
    should 'allow instance methods to the proxied object to access associations' do
      assert_equal @parent.call_company, @parent.company
    end
    
    should 'return original connection after accessing a belongs_to association' do
      assert_releases_connection(Company) do
        AggregateEmployee.find_by_source('one').company
      end
    end
    
  end
  
end