module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args: [], namespace: nil)
      args = wrap_args(args)
      wrap_call build_instance(args, namespace: namespace)
    end

    private

    def wrap_args(args)
      args = with unless with.nil?
      args.is_a?(Array) ? args : [args]
    end

    def wrap_call(the_instance)
      return the_instance unless call

      if the_instance.respond_to? :call
        raise Injectable::MethodAlreadyExistsException
      end

      the_instance.tap do |instance|
        call_method = call

        instance.define_singleton_method(:call) do |*args, &block|
          send(call_method, *args, &block)
        end
      end
    end

    def build_instance(args, namespace:)
      block.nil? ? klass(namespace: namespace).new(*args) : block.call(*args)
    end

    def klass(namespace:)
      self.class || resolve(namespace: namespace)
    end

    def resolve(namespace:)
      (namespace || Object).const_get(camelcased)
    end

    def camelcased
      @camelcased ||= name.to_s.split('_').map(&:capitalize).join
    end
  end
end
