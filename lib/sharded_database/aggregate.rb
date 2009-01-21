module ShardedDatabase
  class NoConnectionError < StandardError ; end
    
  module Aggregate

    def self.included(klass)
      klass.extend         ClassMethods
      klass.send :include, InstanceMethods
      klass.class_eval do
        cattr_accessor :source_class, :foreign_id
        @foreign_id = :other_id

        class << self
          alias_method_chain :find, :aggregate_proxy
        end
      end
    end

    module ClassMethods

      def find_with_aggregate_proxy(*args)
        without_aggregate_proxy = args.last.is_a?(Hash) && args.last.delete(:aggregate_proxy).is_a?(FalseClass)
        if without_aggregate_proxy
          temporarily_undef_method(:after_find) { find_without_aggregate_proxy(*args) }
        else
          find_without_aggregate_proxy(*args)
        end
      end
      
      def preserve_attributes(*attrs)
        @preserved_attributes = attrs.map(&:to_s)
      end

    end

    module InstanceMethods
      
      def sharded_connection_klass
        raise NotImplementedError,
          "You must implement your own #sharded_connection_klass method that returns an ActiveRecord::Base subclass which yeilds a connection."
      end
      
      def after_find
        @klass      = sharded_connection_klass
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