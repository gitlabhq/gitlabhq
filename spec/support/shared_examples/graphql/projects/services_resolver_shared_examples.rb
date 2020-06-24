# frozen_string_literal: true

RSpec.shared_examples 'no project services' do
  it 'returns empty collection' do
    expect(resolve_services).to eq []
  end
end

RSpec.shared_examples 'cannot access project services' do
  it 'raises error' do
    expect do
      resolve_services
    end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
  end
end
