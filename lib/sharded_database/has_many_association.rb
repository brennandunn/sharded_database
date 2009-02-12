module ShardedDatabase
  module HasManyAssociation
    
    def self.included(klass)
      klass.class_eval do
        alias_method_chain :initialize, :delegated_connection
      end
    end
    
    def initialize_with_delegated_connection(owner, reflection)
      if @connection_class = reflection.options[:connection_class]
        @original_class = reflection.klass
        reflection.metaclass.class_eval %{
          def klass
            ModelWithConnection.borrow_connection(#{@original_class.name}, #{@connection_class.name})
          end
        }
      end
      initialize_without_delegated_connection(owner, reflection)
    end
    
  end
end

ActiveRecord::Associations::HasManyAssociation.send :include, ShardedDatabase::HasManyAssociation