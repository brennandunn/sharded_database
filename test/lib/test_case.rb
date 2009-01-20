module ShardedDatabase
  class TestCase < Test::Unit::TestCase
    
    def setup_environment(options={})
      setup_database
      setup_models
    end
    
    def breakdown_environment

    end
    
    def test_truth ; end
    
    
    private
    
    def setup_database
      create_db_file = lambda do |file|
        File.delete(file) if File.exist?(file)
        SQLite3::Database.new(file)
      end
      
      # setup aggregate table
      ::ActiveRecord::Base.establish_connection :master
      ::ActiveRecord::Base.class_eval do
        silence do
          connection.create_table :aggregate_estimates, :force => true do |t|
            t.string    :source
            t.integer   :other_id
            t.timestamp :created_at
          end
        end
      end
      
      # setup NUM_db.estimates
      %w(one two).each do |num|
        ::ActiveRecord::Base.establish_connection "#{num}_db".to_sym
        ::ActiveRecord::Base.class_eval do
          silence do
            connection.create_table :estimates, :force => true do |t|
              t.belongs_to  :company
              t.string      :name
            end
            
            connection.create_table :items, :force => true do |t|
              t.belongs_to  :estimate
              t.string      :name
            end
            
            connection.create_table :companies, :force => true do |t|
              t.string      :name
            end
            
          end
        end
      end
      
    end
    
    def setup_models
      one_company = Class.new(Connection::One) { set_table_name 'companies' }
      @company_1 = one_company.create :name => 'One Company'
      
      one_estimate = Class.new(Connection::One) { set_table_name 'estimates' ; has_many(:items) ; belongs_to(:company) }
      @one_1 = one_estimate.create :name => 'One Estimate', :company_id => @company_1.id
      
      two_estimate = Class.new(Connection::Two) { set_table_name 'estimates' ; has_many(:items) }
      @two_1 = two_estimate.create :name => 'One Estimate 1'
      @two_2 = two_estimate.create :name => 'Two Estimate 2'
      
      one_item = Class.new(Connection::One) { set_table_name 'items' ; belongs_to(:estimate) }
      one_item.create :name => 'One Test Item', :estimate_id => @one_1.id
            
      AggregateEstimate.create :source => 'one', :other_id => @one_1.id
      AggregateEstimate.create :source => 'two', :other_id => @two_1.id
      AggregateEstimate.create :source => 'two', :other_id => @two_2.id
    end
    
  end
end

