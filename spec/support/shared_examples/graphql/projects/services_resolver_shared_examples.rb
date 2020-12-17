# frozen_string_literal: true

RSpec.shared_examples 'no project services' do
  it 'returns empty collection' do
    expect(resolve_services).to be_empty
  end
end

RSpec.shared_examples 'cannot access project services' do
  it 'raises error' do
    expect(resolve_services).to be_nil
  end
end
