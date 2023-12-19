# frozen_string_literal: true

RSpec.shared_examples 'mergeability check service' do |identifier, description|
  it 'sets the identifier' do
    expect(described_class.identifier).to eq(identifier)
  end

  it 'sets the description' do
    expect(described_class.description).to eq(description)
  end
end
