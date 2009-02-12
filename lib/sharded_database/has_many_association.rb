module ShardedDatabase
  module HasManyAssociation
    
    def self.included(klass)
      klass.class_eval do
        alias_method_chain :initialize, :connection
        #alias_method_chain :find, :connection
      end
    end
    
    def initialize_with_connection(owner, reflection)
      if @connection_class = reflection.options[:connection_class]
        @original_class = reflection.klass
        reflection.metaclass.class_eval %{
          def klass
            ModelWithConnection.borrow_connection(#{@original_class.name}, #{@connection_class.name})
          end
        }
      end
      initialize_without_connection(owner, reflection)
    end
    
    def find_with_connection(*args)
      if connection_class = @reflection.options[:connection_class]
        ShardedDatabase::ModelWithConnection.borrow_connection(@reflection.klass, connection_class) do
          find_without_connection(*args)
        end
      else
        find_without_connection(*args)
      end
    end
    
  end
end

ActiveRecord::Associations::HasManyAssociation.send :include, ShardedDatabase::HasManyAssociation
ActiveRecord::Associations::HasManyThroughAssociation.send :include, ShardedDatabase::HasManyAssociation