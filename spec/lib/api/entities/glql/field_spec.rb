# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Glql::Field, feature_category: :custom_dashboards_foundation do
  let(:field) { { key: 'title', label: 'Title', name: 'title', field: 'title' } }
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

  it 'exposes the field' do
    expect(entity_json[:field]).to eq('title')
  end

  context 'with analytics mode field' do
    let(:field) do
      {
        key: 'p50',
        label: 'p50',
        name: 'p50',
        field: 'durationQuantile',
        type: 'metric',
        parameters: { 'quantile' => '0.5' }
      }
    end

    it 'exposes the field' do
      expect(entity_json[:field]).to eq('durationQuantile')
    end

    it 'exposes the type' do
      expect(entity_json[:type]).to eq('metric')
    end

    it 'exposes the parameters' do
      expect(entity_json[:parameters]).to eq({ 'quantile' => '0.5' })
    end
  end

  context 'when field is absent from the input' do
    let(:field) { { key: 'title', label: 'Title', name: 'title' } }

    it 'includes field as nil' do
      expect(entity_json).to have_key(:field)
      expect(entity_json[:field]).to be_nil
    end
  end

  context 'with standard field without type or parameters' do
    it 'does not include type' do
      expect(entity_json).not_to have_key(:type)
    end

    it 'does not include parameters' do
      expect(entity_json).not_to have_key(:parameters)
    end
  end
end
