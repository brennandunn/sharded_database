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
          
          load_target.metaclass.send(:attr_accessor, :source_class)
          load_target.source_class = @klass
          method = a.name
          load_target.class_eval %{
            def #{method}(*args)
              return @#{method} if @#{method}
          
              if proxy_#{method}.respond_to?(:proxy_reflection)
                proxy_#{method}.proxy_reflection.klass.metaclass.delegate :connection, :to => self.source_class
                proxy_#{method}
              else
                # Hacked implementation of belongs_to to superficially simulate an association proxy
                # Revisit this later and do it properly.
          
                reflection = self.class.reflect_on_all_associations.find { |a| a.name == :#{method} }
                klass = reflection.klass            
                klass.metaclass.delegate :connection, :to => self.source_class
                @#{method} ||= klass.find(send(reflection.primary_key_name))            
                @#{method}
              end
            end
          }, __FILE__, __LINE__
        end
        
      end
      
    end

  end

end