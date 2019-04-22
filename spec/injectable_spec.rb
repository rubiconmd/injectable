describe Injectable do
  context 'without defined #call' do
    subject do
      Class.new do
        include Injectable

        def self.to_s
          'MyFancyClass'
        end
      end
    end

    it 'raises an explicit error when using #call' do
      expect { subject.call }.to raise_error(
        NoMethodError,
        'A #call method with zero arity must be defined in MyFancyClass'
      )
    end
  end

  context 'without options' do
    subject do
      Class.new do
        include Injectable

        def call
          'instance #call'
        end
      end
    end

    it 'self.call calls #call on an instance' do
      expect(subject.call).to eq 'instance #call'
    end
  end

  context 'with dependencies' do
    subject do
      Class.new do
        include Injectable

        dependency :third_party do
          'Some third party lib'
        end

        def call
          third_party
        end
      end
    end

    it 'self.call injects default values of dependencies' do
      expect(subject.call).to eq 'Some third party lib'
    end

    it 'allows overriding dependencies' do
      instance = subject.new(third_party: 'Override')
      expect(instance.call).to eq 'Override'
    end
  end

  context 'with dependencies that have plain arguments (not deps) in #initialize' do
    subject do
      Class.new do
        include Injectable

        initialize_with :some_arg, default: 'hardcoded'

        def call
          some_arg
        end
      end
    end

    it 'adds a reader and sets it to a default' do
      expect(subject.call).to eq 'hardcoded'
    end

    it 'supports bypassing the default value' do
      expect(subject.new(some_arg: 'bypass').call).to eq 'bypass'
    end
  end

  context 'with dependencies that have plain arguments (not deps) in #initialize with no default' do
    subject do
      Class.new do
        include Injectable

        initialize_with :some_arg

        def call
          some_arg
        end
      end
    end

    it 'expects the argument to be passed' do
      expect { subject.call }.to raise_error ArgumentError, 'missing keywords: some_arg'
    end

    it 'supports passing a value' do
      expect(subject.new(some_arg: 'bypass').call).to eq 'bypass'
    end
  end

  context 'with dependencies that have a with: array option' do
    before do
      DepWithNormalArg = Class.new do
        attr_reader :somearg
        def initialize(somearg)
          @somearg = somearg
        end
      end
    end

    subject do
      Class.new do
        include Injectable

        dependency :dep_with_normal_arg, with: ['with: arg']

        def call
          dep_with_normal_arg.somearg
        end
      end
    end

    it 'passes it to the dependency #initialize method' do
      expect(subject.call).to eq 'with: arg'
    end
  end

  context 'with dependencies that have a with: keyword option' do
    before do
      DepWithKwargs = Class.new do
        attr_reader :somearg
        def initialize(somearg:)
          @somearg = somearg
        end
      end
    end

    subject do
      Class.new do
        include Injectable

        dependency :dep_with_kwargs, with: { somearg: 'with: arg' }

        def call
          dep_with_kwargs.somearg
        end
      end
    end

    it 'passes it to the dependency #initialize method' do
      expect(subject.call).to eq 'with: arg'
    end
  end

  context 'with dependencies that have a call: option' do
    before do
      SomeRenderer = Class.new do
        def render
          '#render has been called'
        end
      end
    end

    subject do
      Class.new do
        include Injectable

        dependency :some_renderer, call: :render
        delegate :call, to: :some_renderer
      end
    end

    it 'wraps the specified method in a #call method' do
      expect(subject.call).to eq '#render has been called'
    end
  end

  context 'with plural dependencies' do
    before do
      Chicharrons = Class.new
    end

    subject do
      Class.new do
        include Injectable

        dependency :chicharrons

        def call
          chicharrons
        end
      end.call
    end

    it { is_expected.to be_a Chicharrons }
  end

  context 'with dependencies without block' do
    before do
      ExistingClass = Class.new do
        def call
          'This has been constantized!'
        end
      end
    end

    subject do
      Class.new do
        include Injectable
        dependency :existing_class
        delegate :call, to: :existing_class
      end
    end

    it 'casts the name to a class and instantiates it' do
      expect(subject.call).to eq 'This has been constantized!'
    end
  end

  context 'with dependencies without block but with :class' do
    before do
      WeirdName = Class.new do
        def call
          'This has been constantized!'
        end
      end
    end

    subject do
      Class.new do
        include Injectable
        dependency :something_else, class: WeirdName
        delegate :call, to: :something_else
      end
    end

    it 'uses the provided class' do
      expect(subject.call).to eq 'This has been constantized!'
    end
  end

  context 'with arguments' do
    subject do
      Class.new do
        include Injectable

        argument :user_id

        def call
          "Value was #{user_id}"
        end
      end
    end

    it 'allows accessing them with getters' do
      expect(subject.call(user_id: 123)).to eq 'Value was 123'
    end

    it 'requires them' do
      expect { subject.call }.to raise_error(
        ArgumentError,
        'missing keywords: user_id'
      )
    end
  end

  context 'with arguments with default values' do
    subject do
      Class.new do
        include Injectable

        argument :status, default: 'standby'

        def call
          "Value is #{status}"
        end
      end
    end

    it 'allows passing them' do
      expect(
        subject.call(status: 'something_else')
      ).to eq 'Value is something_else'
    end

    it 'sets them to default values if not passed' do
      expect(subject.call).to eq 'Value is standby'
    end
  end

  context 'with recursive dependencies' do
    before do
      InjectedDep = Class.new do
        def call
          'InjectedDep result'
        end
      end

      InjectedClass = Class.new do
        include Injectable

        dependency :injected_dep

        def call
          "I got #{injected_dep.call}"
        end
      end
    end

    subject do
      Class.new do
        include Injectable
        dependency :injected_class
        delegate :call, to: :injected_class
      end
    end

    it 'just works' do
      expect(subject.call).to eq 'I got InjectedDep result'
    end
  end

  context 'with depends_on' do
    before do
      class Counter
        def initialize
          @count = 0
        end

        def count
          @count += 1
        end
      end

      class Somedep
        include Injectable

        dependency :counter

        def call
          "Somedep -> #{counter.count}"
        end
      end

      class Anotherdep
        include Injectable

        dependency :counter

        def call
          "Anotherdep -> #{counter.count}"
        end
      end
    end

    subject do
      Class.new do
        include Injectable
        dependency :counter
        dependency :somedep, depends_on: :counter
        dependency :anotherdep, depends_on: [:counter]

        def call
          "#{somedep.call}, #{anotherdep.call}"
        end
      end
    end

    it 'shares dependency instances' do
      expect(subject.call).to eq 'Somedep -> 1, Anotherdep -> 2'
    end
  end

  context 'with block dependencies that take dependencies' do
    let(:dep) { stub('dep') }

    before do
      class BlockyClass
        include Injectable

        dependency :needed do
          'this is needed'
        end

        dependency :needer, depends_on: :needed do |needed:|
          "I got '#{needed}'"
        end

        def call
          needer
        end
      end
    end

    it 'passes them correctly' do
      expect(BlockyClass.call).to eq "I got 'this is needed'"
    end
  end

  context 'with class inheritance' do
    let(:parent) do
      Class.new do
        include Injectable

        dependency :parent_dep do
          'this comes from parent'
        end

        argument :parent_arg

        def call
          "Returning #{parent_dep} and #{parent_arg}"
        end
      end
    end

    let(:child) do
      Class.new(parent) do
        dependency :child_dep do
          'this is a child dep'
        end
      end
    end

    context 'when calling the child' do
      subject { child.call(parent_arg: 'passed_arg') }

      it { is_expected.to eq 'Returning this comes from parent and passed_arg' }
    end

    context 'adding dependencies to child classes' do
      subject { parent.dependencies.names }

      it { is_expected.not_to include :child_dep }
    end

    context 'with a sibling class' do
      subject { child.call(parent_arg: 'passed_arg') }

      let(:sibling) do
        Sibling = Class.new(parent) do
          argument :required
        end
      end

      it { is_expected.to eq 'Returning this comes from parent and passed_arg' }
    end
  end

  describe 'smart dependency resolution' do
    before do
      class Parent
        class Dependency
          def call
            'in parent'
          end
        end

        include Injectable
        dependency :dependency
        delegate :call, to: :dependency
      end

      class Child < Parent
        class Dependency
          def call
            'in child'
          end
        end
      end

      class Sibling < Parent
        class Dependency
          def call
            'in sibling'
          end
        end
      end
    end

    subject { [Parent.call, Child.call, Sibling.call] }

    it { is_expected.to eq ['in parent', 'in child', 'in sibling']}
  end
end
