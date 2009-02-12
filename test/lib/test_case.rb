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
      
      # Setup master table
      ::ActiveRecord::Base.establish_connection :master
      ::ActiveRecord::Base.class_eval do
        silence do
          connection.create_table :aggregate_employees, :force => true do |t|
            t.string    :source
            t.integer   :other_id
            t.timestamp :created_at
          end
        end
      end
      
      # Setup sharded DBs for employees
      [Connection::One, Connection::Two].each do |klass|
        klass.class_eval do
          silence do
            connection.create_table :employees, :force => true do |t|
              t.belongs_to  :company
              t.string      :name
            end
            
            connection.create_table :items, :force => true do |t|
              t.belongs_to  :employee
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
      
      one_employee = Class.new(Connection::One) { set_table_name 'employees' ; has_many(:items) ; belongs_to(:company) }
      @one_1 = one_employee.create :name => 'One Employee', :company_id => @company_1.id
      
      two_employee = Class.new(Connection::Two) { set_table_name 'employees' ; has_many(:items) }
      @two_1 = two_employee.create :name => 'One Employee 1'
      @two_2 = two_employee.create :name => 'Two Employee 2'
      
      one_item = Class.new(Connection::One) { set_table_name 'items' ; belongs_to(:employee) }
      one_item.create :name => 'One Test Item', :employee_id => @one_1.id
            
      AggregateEmployee.create :source => 'one', :other_id => @one_1.id
      AggregateEmployee.create :source => 'two', :other_id => @two_1.id
      AggregateEmployee.create :source => 'two', :other_id => @two_2.id
    end
    
  end
end

