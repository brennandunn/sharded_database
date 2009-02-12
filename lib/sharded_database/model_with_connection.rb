module ShardedDatabase
  module ModelWithConnection
    
    def self.included(klass)
      klass.extend ClassMethods
      
      klass.class_eval do
        class << self
          alias_method_chain :find, :connection
        end
      end
    end
    
    def self.borrow_connection(requesting_class, target_class, &block)
      @eigen = requesting_class.metaclass
      @eigen.send :alias_method, :proxy_connection, :connection
      @eigen.delegate :connection, :to => target_class
      block_given? ? yield(requesting_class) : requesting_class
    ensure
      @eigen.send :alias_method, :connection, :proxy_connection if block_given?
    end
    
    
    module ClassMethods
      
      def find_with_connection(*args)
        if args.last.is_a?(Hash) && connection_arg = args.last.delete(:connection)
          connection = 
          case connection_arg
          when Symbol then send(connection_arg, *args)
          when Proc then connection_arg.call(*args)
          when Class then connection_arg
          end
          ModelWithConnection.borrow_connection(self, connection) { find_without_connection(*args) }
        else
          find_without_connection(*args)
        end
      end
      
    end
    
    module InstanceMethods
      
    end
    
  end
end