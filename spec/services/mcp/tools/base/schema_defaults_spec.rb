# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Base::SchemaDefaults, feature_category: :mcp_server do
  describe '.with_additional_properties' do
    it 'injects additionalProperties: false when the key is absent' do
      schema = { type: 'object', properties: { name: { type: 'string' } } }

      expect(described_class.with_additional_properties(schema))
        .to eq(type: 'object', properties: { name: { type: 'string' } }, additionalProperties: false)
    end

    it 'leaves an explicit additionalProperties: true unchanged' do
      schema = { type: 'object', properties: {}, additionalProperties: true }

      expect(described_class.with_additional_properties(schema)).to eq(schema)
    end

    it 'leaves an explicit additionalProperties: false unchanged' do
      schema = { type: 'object', properties: {}, additionalProperties: false }

      expect(described_class.with_additional_properties(schema)).to eq(schema)
    end

    it 'respects a string additionalProperties key' do
      schema = { 'type' => 'object', 'additionalProperties' => true }

      expect(described_class.with_additional_properties(schema)).to eq(schema)
    end

    %i[oneOf anyOf allOf $ref].each do |composition_key|
      it "does not inject additionalProperties when #{composition_key} is present" do
        schema = { composition_key => [{ type: 'object' }] }

        expect(described_class.with_additional_properties(schema)).to eq(schema)
      end
    end

    it 'does not inject additionalProperties when a composition key is a string key' do
      schema = { 'oneOf' => [{ type: 'object' }] }

      expect(described_class.with_additional_properties(schema)).to eq(schema)
    end

    it 'does not mutate a frozen input schema' do
      schema = { type: 'object', properties: {} }.freeze

      result = described_class.with_additional_properties(schema)

      expect(result).not_to equal(schema)
      expect(schema).not_to have_key(:additionalProperties)
    end
  end
end
