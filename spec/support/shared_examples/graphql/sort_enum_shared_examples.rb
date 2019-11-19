# frozen_string_literal: true

RSpec.shared_examples 'common sort values' do
  it 'exposes all the existing common sort values' do
    expect(described_class.values.keys).to include(*%w[updated_desc updated_asc created_desc created_asc])
  end
end
