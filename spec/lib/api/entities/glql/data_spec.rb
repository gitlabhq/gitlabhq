# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Glql::Data, feature_category: :integrations do
  let(:data) do
    {
      count: 42,
      nodes: [{ id: '1', title: 'Test Issue' }],
      pageInfo: {
        endCursor: 'eyJpZCI6IjE3In0',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'eyJpZCI6IjE3In0'
      }
    }
  end

  let(:entity) { described_class.new(data) }

  subject(:entity_json) { entity.as_json }

  it 'exposes the count' do
    expect(entity_json[:count]).to eq(42)
  end

  it 'exposes the nodes' do
    expect(entity_json[:nodes]).to match_array([{ id: '1', title: 'Test Issue' }])
  end

  it 'exposes pageInfo' do
    expect(entity_json[:pageInfo]).to be_a(Hash)
  end

  it 'exposes pageInfo endCursor' do
    expect(entity_json[:pageInfo][:endCursor]).to eq('eyJpZCI6IjE3In0')
  end

  it 'exposes pageInfo hasNextPage' do
    expect(entity_json[:pageInfo][:hasNextPage]).to be(true)
  end

  it 'exposes pageInfo hasPreviousPage' do
    expect(entity_json[:pageInfo][:hasPreviousPage]).to be(false)
  end

  it 'exposes pageInfo startCursor' do
    expect(entity_json[:pageInfo][:startCursor]).to eq('eyJpZCI6IjE3In0')
  end
end
