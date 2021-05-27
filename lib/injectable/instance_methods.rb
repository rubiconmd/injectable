module Injectable
  module InstanceMethods
    # Initialize the service with the dependencies injected
    def initialize(args = {})
      check_missing_arguments!(self.class.required_initialize_arguments, args)
      variables_for!(self.class.initialize_arguments, args)
      variables_from_dependencies!(args)
      super()
    end

    # Entry point of the service.
    # Arguments for this method should be declared explicitly with '.argument'
    # and declare this method without arguments
    def call(args = {})
      check_call_definition!
      check_missing_arguments!(self.class.required_call_arguments, args)
      variables_for!(self.class.call_arguments, args)
      super()
    end

    private

    def instantiate_dependency(name)
      deps = self.class.dependencies
      deps[name].instance(args: memoized_dependencies_of(name), namespace: deps.namespace)
    end

    def memoized_dependencies_of(name)
      return [] if dependencies_of(name).empty?

      dependencies_of(name).each_with_object({}) { |dep, hash| hash[dep] = public_send(dep) }
    end

    def dependencies_of(name)
      self.class.dependencies[name].depends_on
    end

    def check_call_definition!
      return if (self.class.ancestors - [Injectable::InstanceMethods]).any? do |ancestor|
        ancestor.instance_methods(false).include?(:call)
      end
      raise NoMethodError, "A #call method with zero arity must be defined in #{self.class}"
    end

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
        next unless args.key?(name)
        next instance_variable_set("@#{name}", args[name]) unless args[name].respond_to?(:new)
        next instance_variable_set("@#{name}", args[name].new) if dependencies_of(name).empty?

        instance_variable_set("@#{name}",  args[name].new(memoized_dependencies_of(name))) 
      end
    end
  end
end
