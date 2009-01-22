module ShardedDatabase
  module AggregateProxy

    def ===(other)
      other === load_target
    end

    def inspect
      load_target.inspect.gsub(/#<([\w\:]+)\s(.*?)>/) { "#<#{$1}(#{@klass.name}) #{$2}>" }
    end

    def respond_to?(method)
      load_target.respond_to?(method) || super
    end


    private

    def load_target
      @target ||= begin
                    klass = (self.proxy_class.instance_variable_get('@source_class')).constantize
                    ModelWithConnection.borrow_connection(klass, @klass) { |k| k.find(@foreign_id) }
                  end
    end

    def method_missing(method, *args, &block)
      load_target.respond_to?(method) ? load_target.send(method, *args, &block) : super
    end

    def association_method?(method)
      load_target.class.reflect_on_all_associations.any? { |a| a.name == method.to_sym }
    end

  end
end
