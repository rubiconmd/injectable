describe Injectable::DependenciesProxy, '#get' do
  let(:graph) do
    Injectable::DependenciesProxy.new(
      dependency: dependency,
      dependent:  dependent
    )
  end

  let(:dependent)  { stub('Dep that depends on something', depends_on: [:dependency]) }
  let(:dependency) { stub('Dependency', depends_on: []) }
  let(:dependency_instance) { stub('Dependency instance') }

  before do
    dependency.stubs(:instance).with([]).once.returns(dependency_instance)
  end

  subject { graph.get(target) }

  it 'memoizes instances' do
    expect(graph.get(:dependency)).to eq graph.get(:dependency)
  end

  context 'for dependencies without dependencies' do
    let(:target) { :dependency }

    it { is_expected.to eq dependency_instance }
  end

  context 'for dependencies with dependencies' do
    let(:target) { :dependent }
    let(:dependent_instance) { stub('Dependent instance') }

    before do
      dependent.stubs(:instance).with(dependency: dependency_instance).returns(dependent_instance)
    end

    it { is_expected.to eq dependent_instance }
  end
end
