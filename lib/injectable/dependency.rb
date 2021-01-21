module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args: [], namespace: nil)
      positional_args, kwargs = split_args(args)

      wrap_call build_instance(positional_args, kwargs, namespace: namespace)
    end

    private

    def split_args(args)
      positional_args = []
      kwargs = {}

      preprocess_args(args).each do |arg|
        arg.is_a?(Hash) ? kwargs.merge!(arg) : positional_args << arg
      end

      [positional_args, kwargs]
    end

    def preprocess_args(args)
      args = with unless with.nil?
      wrap_args(args)
    end

    def wrap_args(args)
      args.is_a?(Array) ? args : [args]
    end

    def wrap_call(the_instance)
      return the_instance unless call

      if the_instance.respond_to? :call
        raise Injectable::MethodAlreadyExistsException
      end

      the_instance.public_method(call)
    end

    def build_instance(args, kwargs, namespace:)
      return build_instance_26(args, kwargs, namespace: namespace) if RUBY_VERSION < '2.7'

      block.nil? ? klass(namespace: namespace).new(*args, **kwargs) : block.call(*args, **kwargs)
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

    def build_instance_26(args, kwargs, namespace:)
      args << kwargs if kwargs.any?

      block.nil? ? klass(namespace: namespace).new(*args) : block.call(*args)
    end
  end
end
