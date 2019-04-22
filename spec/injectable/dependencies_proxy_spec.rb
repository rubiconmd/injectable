describe Injectable::DependenciesProxy, '#get' do
  let(:graph) do
    Injectable::DependenciesProxy.new(
      namespace: ns,
      graph: {
        dependency: dependency,
        dependent: dependent
      }
    )
  end

  let(:ns) { stub('Namespace') }
  let(:dependent)  { stub('Dep that depends on something', depends_on: [:dependency]) }
  let(:dependency) { stub('Dependency', depends_on: []) }
  let(:dependency_instance) { stub('Dependency instance') }

  before do
    dependency.stubs(:instance).with(args: [], namespace: ns).once.returns(dependency_instance)
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
      dependent.stubs(:instance)
               .with(args: { dependency: dependency_instance }, namespace: ns)
               .returns(dependent_instance)
    end

    it { is_expected.to eq dependent_instance }
  end
end
