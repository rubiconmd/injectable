module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args: [], namespace: nil)
      args = wrap_args(args)
      wrap_call build_instance(args, namespace: namespace)
    end

    private

    def wrap_args(args)
      args = with if with.present?
      args.is_a?(Array) ? args : [args]
    end

    def wrap_call(the_instance)
      return the_instance unless call

      lambda do |*args|
        the_instance.public_send(call, *args)
      end
    end

    def build_instance(args, namespace:)
      block.present? ? block.call(*args) : klass(namespace: namespace).new(*args)
    end

    def klass(namespace:)
      self.class || resolve(namespace: namespace)
    end

    def resolve(namespace:)
      (namespace || Object).const_get(name.to_s.camelize)
    end
  end
end
