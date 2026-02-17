# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Glql::Result, feature_category: :integrations do
  let(:result) do
    {
      data: {
        count: 42,
        nodes: [{ id: '1', title: 'Test Issue' }],
        pageInfo: {
          endCursor: 'eyJpZCI6IjE3In0',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjE3In0'
        }
      },
      error: nil,
      fields: [
        { key: 'title', label: 'Title', name: 'title' },
        { key: 'state', label: 'State', name: 'state' }
      ],
      success: true
    }
  end

  let(:entity) { described_class.new(result) }

  subject(:entity_json) { entity.as_json }

  it 'exposes the data' do
    expect(entity_json[:data]).to be_a(Hash)
    expect(entity_json[:data][:count]).to eq(42)
    expect(entity_json[:data][:nodes]).to be_an(Array)
    expect(entity_json[:data][:pageInfo]).to be_a(Hash)
  end

  it 'exposes the error' do
    expect(entity_json[:error]).to be_nil
  end

  it 'exposes the fields' do
    expect(entity_json[:fields]).to be_an(Array)
    expect(entity_json[:fields].size).to eq(2)
    expect(entity_json[:fields].first[:key]).to eq('title')
  end

  it 'exposes the success flag' do
    expect(entity_json[:success]).to be(true)
  end

  context 'when there is an error' do
    let(:result) do
      {
        data: { count: 0, nodes: [], pageInfo: {} },
        error: 'Something went wrong',
        fields: [],
        success: false
      }
    end

    it 'exposes the error message' do
      expect(entity_json[:error]).to eq('Something went wrong')
    end

    it 'exposes success as false' do
      expect(entity_json[:success]).to be(false)
    end
  end
end
