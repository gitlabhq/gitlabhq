# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Glql::Field, feature_category: :integrations do
  let(:field) { { key: 'title', label: 'Title', name: 'title' } }
  let(:entity) { described_class.new(field) }

  subject(:entity_json) { entity.as_json }

  it 'exposes the key' do
    expect(entity_json[:key]).to eq('title')
  end

  it 'exposes the label' do
    expect(entity_json[:label]).to eq('Title')
  end

  it 'exposes the name' do
    expect(entity_json[:name]).to eq('title')
  end
end
