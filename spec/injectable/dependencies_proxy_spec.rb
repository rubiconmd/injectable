describe Injectable::DependenciesProxy, '#get' do
  let(:graph) do
    Injectable::DependenciesProxy.new(
      dependency: dependency,
      dependent:  dependent
    )
  end

  let(:dependent)  { double('Dep that depends on something', depends_on: [:dependency]) }
  let(:dependency) { double('Dependency', depends_on: []) }
  let(:dependency_instance) { double('Dependency instance') }

  before do
    allow(dependency).to receive(:instance).with([]).and_return(dependency_instance)
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
    let(:dependent_instance) { double('Dependent instance') }

    before do
      allow(dependent).to receive(:instance).with(dependency: dependency_instance).and_return(dependent_instance)
    end

    it { is_expected.to eq dependent_instance }
  end
end
