# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Glql::PageInfo, feature_category: :integrations do
  let(:page_info) do
    {
      endCursor: 'eyJpZCI6IjE3In0',
      hasNextPage: true,
      hasPreviousPage: false,
      startCursor: 'eyJpZCI6IjE3In0'
    }
  end

  let(:entity) { described_class.new(page_info) }

  subject(:entity_json) { entity.as_json }

  it 'exposes the endCursor' do
    expect(entity_json[:endCursor]).to eq('eyJpZCI6IjE3In0')
  end

  it 'exposes hasNextPage' do
    expect(entity_json[:hasNextPage]).to be(true)
  end

  it 'exposes hasPreviousPage' do
    expect(entity_json[:hasPreviousPage]).to be(false)
  end

  it 'exposes the startCursor' do
    expect(entity_json[:startCursor]).to eq('eyJpZCI6IjE3In0')
  end
end
