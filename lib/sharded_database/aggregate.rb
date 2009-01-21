module ShardedDatabase
  class NoConnectionError < StandardError ; end
    
  module Aggregate

    def self.included(klass)
      klass.extend         ClassMethods
      klass.send :include, InstanceMethods
      klass.class_eval do
        cattr_accessor :connection_field, :source_class, :foreign_id
        @connection_field = :oem
        @foreign_id = :other_id

        class << self
          alias_method_chain :find, :raw
        end
      end
    end

    module ClassMethods

      def find_with_raw(*args)
        @raw = args.last.is_a?(Hash) && args.last.delete(:raw)
        @raw ? temporarily_undef_method(:after_find) { find_without_raw(*args) } : find_without_raw(*args)
      end

      def preserve_attributes(*attrs)
        @preserved_attributes = attrs.map(&:to_s)
      end

    end

    module InstanceMethods
      
      def determine_connection
        # stub method - implement your own!
      end
      
      def after_find
        @klass      = determine_connection || raise(ShardedDatabase::NoConnectionError, 'Cannot determine connection class')
        @connection = @klass.respond_to?(:connection) ? @klass.connection : raise(ShardedDatabase::NoConnectionError, 'Connection class does not respond to :connection')
        @foreign_id = self[self.class.foreign_id.to_sym]

        metaclass.delegate :connection, :to => @klass

        (self.class.instance_variable_get("@preserved_attributes") || []).each do |attr|
          metaclass.send :alias_method, "proxy_#{attr}", attr
        end

        class << self
          alias_method :proxy_class, :class

          include AggregateProxy
          instance_methods.each do |m|
            undef_method(m) unless m =~ /^__|proxy_|inspect/
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