module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args: [], namespace: nil)
      positional_args, kwargs = wrap_args(args)

      wrap_call build_instance(positional_args, kwargs, namespace: namespace)
    end

    private

    def wrap_args(args)
      args = with unless with.nil?

      args_splitter(args)
    end

    def wrap_call(the_instance)
      return the_instance unless call

      if the_instance.respond_to? :call
        raise Injectable::MethodAlreadyExistsException
      end

      the_instance.public_method(call)
    end

    def build_instance(args, kwargs, namespace:)
      return klass(namespace: namespace).new(*args, **kwargs) if block.nil?

      block.call(*args, **kwargs)
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

    def args_splitter(args)
      args = args.is_a?(Array) ? args : [args]

      positional_args = []
      kwargs = {}

      args.each { |arg| arg.is_a?(Hash) ? kwargs.merge!(arg) : positional_args << arg }

      return positional_args, kwargs
    end
  end
end
