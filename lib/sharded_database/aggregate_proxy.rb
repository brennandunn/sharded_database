module ShardedDatabase
  module AggregateProxy

    def ===(other)
      other === load_target
    end

    def inspect
      load_target.inspect.gsub(/#<([\w\:]+)\s(.*?)>/) { "#<#{$1}(#{@klass.name}) #{$2}>" }
    end


    private

    def load_target
      @target ||= begin
                    klass = (self.proxy_class.source_class || self.proxy_class.name.gsub('Aggregate','')).constantize
                    borrow_connection(klass, @klass) { |k| k.find(@foreign_id) }
                  end
    end

    def method_missing(method, *args, &block)
      if association_method?(method)
        apply_connection_to_association(method)
      end
      load_target.respond_to?(method) ? load_target.send(method, *args, &block) : super
    end

    def association_method?(method)
      load_target.class.reflect_on_all_associations.any? { |a| a.name == method.to_sym }
    end

    def borrow_connection(requesting_class, target_class, &block)
      eigen = requesting_class.metaclass
      eigen.delegate :connection, :to => target_class
      yield(requesting_class)
    end
    
    def apply_connection_to_association(method)
      load_target.metaclass.send(:attr_accessor, :source_class)
      load_target.source_class = @klass
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
