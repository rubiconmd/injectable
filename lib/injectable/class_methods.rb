module Injectable
  module ClassMethods
    def self.extended(base)
      base.class_eval do
        simple_class_attribute :dependencies,
                               :initialize_arguments

        self.dependencies = DependenciesGraph.new(namespace: base)
        self.initialize_arguments = {}
      end
    end

    def inherited(base)
      base.class_eval do
        self.dependencies = dependencies.with_namespace(base)
        self.initialize_arguments = initialize_arguments.dup
      end
    end

    # Blatantly stolen from rails' ActiveSupport.
    # This is a simplified version of class_attribute
    def simple_class_attribute(*attrs)
      attrs.each do |name|
        define_singleton_method(name) { nil }

        ivar = "@#{name}"

        define_singleton_method("#{name}=") do |val|
          singleton_class.class_eval do
            define_method(name) { val }
          end

          if singleton_class?
            class_eval do
              define_method(name) do
                if instance_variable_defined? ivar
                  instance_variable_get ivar
                else
                  singleton_class.send name
                end
              end
            end
          end
          val
        end
      end
    end

    # Use the service with the params declared with '.argument'
    # @param args [Hash] parameters needed for the Service
    # @example MyService.call(foo: 'first_argument', bar: 'second_argument')
    def call(**)
      new.call(**)
    end

    # Declare dependencies for the service
    # @param name [Symbol] the name of the service
    # @option options [Class] :class The class to use if it's different from +name+
    # @option options [Symbol, Array<Symbol>] :depends_on if the dependency has more dependencies
    # @yield explicitly declare the dependency
    #
    # @return [Object] the injected dependency
    #
    # @example Using the same name as the service object
    #   dependency :team_query
    #     # => @team_query = TeamQuery.new
    #
    # @example Specifying a different class
    #   dependency :player_query, class: UserQuery
    #     # => @player_query = UserQuery.new
    #
    # @example With a block
    #   dependency :active_players do
    #     ->(players) { players.select(&:active?) }
    #   end
    #     # => @active_players = [lambda]
    #
    # @example With more dependencies
    #   dependency :counter
    #   dependency :team_service
    #   dependency :player_counter, depends_on: [:counter, :team_service]
    #     # => @counter = Counter.new
    #     # => @team_service = TeamService.new
    #     # => @player_counter = PlayerCounter.new(counter: @counter, team_service: @team_service)
    #
    # @example Dependencies that don't accept keyword arguments
    #   dependency :counter
    #   dependency :player_counter, depends_on: :counter do |counter:|
    #     PlayerCounter.new(counter)
    #   end
    #     # => @counter = Counter.new
    #     # => @player_counter = PlayerCounter.new(@counter)
    def dependency(name, options = {}, &block)
      options[:block] = block if block_given?
      options[:depends_on] = Array(options.fetch(:depends_on, []))
      options[:name] = name
      dependencies.add(**options)
      define_method name do
        instance_variable_get("@#{name}") || dependencies_proxy.get(name)
      end
    end

    def initialize_with(name, options = {})
      initialize_arguments[name] = options
      attr_accessor name
    end

    # Get the #initialize arguments declared with '.initialize_with' with no default
    # @private
    def required_initialize_arguments
      find_required_arguments initialize_arguments
    end

    def find_required_arguments(hash)
      hash.reject { |_arg, options| options.key?(:default) }.keys
    end
  end
end
