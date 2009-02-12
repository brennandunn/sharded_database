module ShardedDatabase
  class NoConnectionError < StandardError ; end
    
  module Aggregate

    def self.included(klass)
      klass.extend         ClassMethods
      klass.send :include, InstanceMethods
      klass.class_eval do
        cattr_accessor :foreign_id
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
      
      def source_class(klass_name)
        @source_class = klass_name
        apply_model_with_connection_to(klass_name)
      end
      
      
      private
      
      def apply_model_with_connection_to(klass_name)
        require_dependency klass_name.underscore unless defined?(klass_name.constantize)  # ensure that the source class has been loaded
        klass_name.constantize.send :include, ShardedDatabase::ModelWithConnection
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
        
        preserve_attributes
        apply_proxy
        channel_associations_to_proper_connection
      end
      
      
      private
      
      def preserve_attributes
        (self.class.instance_variable_get("@preserved_attributes") || []).each do |attr|
          metaclass.send :alias_method, "original_#{attr}", attr
        end
      end
      
      def apply_proxy
        class << self
          alias_method :proxy_class, :class
          
          include AggregateProxy
          instance_methods.each do |m|
            undef_method(m) unless m =~ /^__|proxy_|original_|inspect/
          end
        end
      end

      def channel_associations_to_proper_connection
        self.class.reflect_on_all_associations.each do |association|
          metaclass.class_eval %{
            
            def #{association.name}_with_connection(*args)
              reflection = self.class.reflect_on_association(:#{association.name})
              reflection.options.merge!({ :connection_class => #{@klass.name}} )
              klass = reflection.klass
              ModelWithConnection.borrow_connection(klass, #{@klass.name}) do
                #{association.name}_without_connection(*args)
              end
            end
            
          }, __FILE__, __LINE__
          metaclass.send :alias_method_chain, association.name, :connection
        end
      end
      
    end

  end

end