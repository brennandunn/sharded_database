require File.dirname(__FILE__) + '/../helper'

class InstanceTest < ShardedDatabase::TestCase
  def setup ; setup_environment ; end
  
  
  context 'Loading raw aggregate objects' do
    
    setup do
      @aggregates = AggregateEstimate.all(:raw => true)
    end
    
    should 'all be AggregateEstimate instances' do
      assert @aggregates.all? { |a| a.is_a?(AggregateEstimate) }
    end
    
  end
  
  context "A transformed aggregate instance" do
    
    setup do
      @estimate = AggregateEstimate.first
    end

    should 'channel calls to #class to the proxy class' do
      assert @estimate.is_a?(Estimate)
    end
    
    should 'have the same attribute fields as the proxy class' do
      assert_same_elements @estimate.attributes.keys, Estimate.column_names
    end
    
  end
  
end