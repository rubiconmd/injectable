module Injectable
  module InstanceMethods
    # Initialize the service with the dependencies injected
    def initialize(args = {})
      check_missing_arguments!(self.class.required_initialize_arguments, args)
      variables_for!(self.class.initialize_arguments, args)
      variables_from_dependencies!(args)
      super()
    end

    private

    def check_missing_arguments!(expected, args)
      missing = expected - args.keys
      return if missing.empty?
      raise ArgumentError, "missing keywords: #{missing.join(',')}"
    end

    def variables_for!(subject, args)
      subject.each do |arg, options|
        instance_variable_set("@#{arg}", args.fetch(arg) { options[:default] })
      end
    end

    def variables_from_dependencies!(args)
      self.class.dependencies.names.each do |name|
        next if self.class.initialize_arguments.key?(name)
        instance_variable_set("@#{name}", args[name]) if args.key?(name)
      end
    end

    def dependencies_proxy
      @dependencies_proxy ||= self.class.dependencies.proxy
    end
  end
end
