describe Injectable::DependenciesGraph, '#resolve' do
  let(:ns)    { double('Namespace') }
  let(:graph) { described_class.new(namespace: ns) }

  context 'when depending on a dependency not declared' do
    subject do
      graph.add(name: :something, depends_on: %i[missing none])
    end

    it 'raises an exception' do
      message = 'missing dependencies: missing, none'
      expect { subject }.to raise_error Injectable::MissingDependenciesException, message
    end
  end
end
