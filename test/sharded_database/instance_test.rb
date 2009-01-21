require File.dirname(__FILE__) + '/../helper'

class InstanceTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  context 'Loading non-proxyable aggregate objects' do
    
    setup do
      @aggregates = AggregateEmployee.all(:aggregate_proxy => false)
    end
    
    should 'all be AggregateEmployee instances' do
      assert @aggregates.all? { |a| a.is_a?(AggregateEmployee) }
    end
    
  end
  
  context "A transformed aggregate instance" do
    
    setup do
      @employee = AggregateEmployee.first
    end

    should 'channel calls to #class to the proxy class' do
      assert @employee.is_a?(Employee)
    end
    
    should 'have the same attribute fields as the proxy class' do
      assert_same_elements @employee.attributes.keys, Employee.column_names
    end
    
    should 'preserve attributes supplied to #preserve_attributes' do
      assert_equal 'one', @employee.proxy_source
    end
    
  end
  
end