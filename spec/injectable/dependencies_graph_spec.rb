describe Injectable::DependenciesGraph, '#resolve' do
  let(:graph) { described_class.new }

  context 'when depending on a dependency not declared' do
    subject do
      graph.add(name: :something, depends_on: %i[missing none])
    end

    it 'raises an exception' do
      message = 'missing dependencies: missing, none'
      expect { subject }.to raise_error Injectable::MissingDependenciesException, message
    end
  end

  context '#proxy' do
    let(:proxy_class) { stub('Proxy class') }
    let(:proxy) { stub('Proxy instance') }
    let(:dependency_class) { stub('Dependency class') }
    let(:dependency) { stub('Dependency instance') }
    let(:graph) do
      described_class.new(proxy_class: proxy_class, dependency_class: dependency_class)
    end

    let(:name) { :some_name }
    let(:options) { { name: name, depends_on: [] } }

    before do
      dependency_class.stubs(:new).with(options).returns(dependency)
      proxy_class.stubs(:new).with(name => dependency).returns(proxy)
      graph.add(options)
    end

    subject { graph.proxy }

    it { is_expected.to eq proxy }
  end
end
