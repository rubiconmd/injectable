module Injectable
  # Initialize a dependency based on the options or the block passed
  Dependency = Struct.new(:name, :block, :class, :call, :with, :depends_on, keyword_init: true) do
    def instance(args = [])
      args = wrap_args(args)
      wrap_call build_instance(args)
    end

    private

    def wrap_args(args)
      args = with unless with.nil?
      args.is_a?(Array) ? args : [args]
    end

    def wrap_call(the_instance)
      return the_instance unless call

      lambda do |*args|
        the_instance.public_send(call, *args)
      end
    end

    def build_instance(args)
      block.nil? ? klass.new(*args) : block.call(*args)
    end

    def klass
      @klass ||= self.class || constantize
    end

    def constantize
      Object.const_get(camelcased)
    end

    def camelcased
      @camelcased ||= name.to_s.split('_').map(&:capitalize).join
    end
  end
end
