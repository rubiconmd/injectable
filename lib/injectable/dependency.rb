module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args = [])
      args = wrap_args(args)
      wrap_call build_instance(args)
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

    def build_instance(args)
      block.present? ? block.call(*args) : klass.new(*args)
    end

    def klass
      @klass ||= self.class || name.to_s.camelcase.constantize
    end
  end
end
