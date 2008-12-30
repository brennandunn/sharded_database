module ShardedDatabase
  class NoConnectionError < StandardError ; end
    
  module Aggregate

    def self.included(klass)
      klass.extend         ClassMethods
      klass.send :include, InstanceMethods
      klass.class_eval do
        cattr_accessor :connection_field, :source_class
        @connection_field = :oem

        class << self
          alias_method_chain :find, :raw
        end
      end
    end

    module ClassMethods

      def find_with_raw(*args)
        @raw = args.last.is_a?(Hash) && args.last.delete(:raw)
        @raw ? temporarily_remove(:after_find) { find_without_raw(*args) } : find_without_raw(*args)
      end

    end

    module InstanceMethods
      
      def determine_connection
        # stub method - implement your own!
      end
      
      def after_find
        @klass      = determine_connection || raise(ShardedDatabase::NoConnectionError, 'Cannot determine connection class')
        @connection = @klass.respond_to?(:connection) ? @klass.connection : raise(ShardedDatabase::NoConnectionError, 'Connection class does not respond to :connection')
        @foreign_id = foreign_id

        metaclass.delegate :connection, :to => @klass

        class << self
          alias_method :proxy_class, :class

          include AggregateProxy
          instance_methods.each do |m|
            undef_method(m) unless m =~ /^__|proxy_|inspect|foreign_id/
          end
        end
        
        self.class.reflect_on_all_associations.each do |a| 
          metaclass.send :alias_method, "proxy_#{a.name}".to_sym, a.name.to_sym
          metaclass.send :undef_method, a.name
        end
        
      end
      
    end

  end

end