require 'rails_helper'

RSpec.shared_examples 'a registered kubernetes app' do
  let(:name) { described_class::NAME }

  it 'can be retrieved with Clusters::Kubernetes.app' do
    expect(Clusters::Kubernetes.app(name)).to eq(described_class)
  end
end
