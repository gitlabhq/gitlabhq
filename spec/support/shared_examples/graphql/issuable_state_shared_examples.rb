# frozen_string_literal: true

RSpec.shared_examples 'issuable state' do
  it 'exposes all the existing issuable states' do
    expect(described_class.values.keys).to include(*%w[opened closed locked])
  end
end
