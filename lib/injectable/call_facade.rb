module Injectable
  module CallFacade
    def self.[](klass)
      m = Module.new do
        # Entry point of the service.
        # Arguments for this method should be declared explicitly with '.argument'
        # and declare this method without arguments
        define_method :call do |args = {}|
          if self.instance_of?(klass)
            check_call_definition!
            check_missing_arguments!(self.class.required_call_arguments, args)
            variables_for!(self.class.call_arguments, args)
          end

          super()
        end

        def self.facade?
          true
        end
      end

      klass.const_set(:InjectableCallFacade, m)
    end
  end
end
