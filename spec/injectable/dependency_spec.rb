describe Injectable::Dependency, 'instance' do
  let(:name) { 'my_dependency' }
  let(:options) { { name: name } }
  let(:described_instance) { described_class.new(options) }
  subject { described_instance.instance }

  before do
    class MyDependency
    end
  end

  it { is_expected.to be_a(MyDependency) }

  describe 'instance memoization' do
    subject { described_instance }

    it 'does not retain the instance' do
      expect(subject.instance).not_to equal subject.instance
    end
  end

  describe 'with arguments' do
    let(:klass) do
      Class.new do
        attr_reader :arg

        def initialize(arg)
          @arg = arg
        end
      end
    end
    let(:options) { { class: klass } }
    subject { described_instance.instance(['some arg']).arg }

    it { is_expected.to eq 'some arg' }
  end

  describe 'with keyword arguments' do
    let(:klass) do
      Class.new do
        attr_reader :kwarg

        def initialize(kwarg:)
          @kwarg = kwarg
        end
      end
    end
    let(:options) { { class: klass } }
    subject { described_instance.instance(kwarg: 'some arg').kwarg }

    it { is_expected.to eq 'some arg' }
  end

  context 'when it receives the class: option' do
    let(:options) { { "class": Namespaced::Dep } }
    before do
      module Namespaced
        class Dep
        end
      end
    end

    it { is_expected.to be_a(Namespaced::Dep) }
  end

  context 'when it receives a block' do
    let(:some_dep) { stub('some_dep') }
    let(:options)  { { block: -> { some_dep } } }

    it { is_expected.to eq some_dep }
  end

  context 'when it receives the call: option' do
    let(:options) { { call: :render, block: -> { renderer } } }
    let(:result)  { stub('Result') }
    let(:renderer) { stub('Renderer', render: result) }

    it 'wraps the specified method in a proc' do
      expect(subject.call).to eq result
    end
  end

  context 'when it receives the with: option' do
    let(:options) { { with: [somearg], class: dependency } }
    let(:dependency) { stub('Dependency') }
    let(:somearg) { stub('Argument passed with :with option') }
    let(:expected) { stub('Expected return') }

    before do
      dependency.stubs(:new).with(somearg).returns(expected)
    end

    it { is_expected.to eq expected }
  end
end
