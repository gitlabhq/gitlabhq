# frozen_string_literal: true

require 'fast_spec_helper'
require 'oj'
require_relative Rails.root.join('lib/ci/pipeline_creation/inputs.rb')

RSpec.describe Ci::PipelineCreation::Inputs, feature_category: :pipeline_composition do
  describe '.parse_params' do
    let(:params) do
      {
        'string_param' => 'regular-string',
        json_array: '[1, 2, 3]',
        'json_object' => '{"key": "value"}',
        'json_boolean' => 'true',
        'json_number' => '42',
        'nested' => { 'param' => 'value' }
      }
    end

    subject(:parse_params) { described_class.parse_params(params) }

    it 'transforms values' do
      expect(parse_params).to include(
        string_param: 'regular-string',
        json_array: [1, 2, 3],
        json_object: { key: 'value' },
        json_boolean: true,
        json_number: 42,
        nested: { param: 'value' }
      )
    end

    context 'when params are not a hash' do
      let(:params) { 'not a hash' }

      it 'returns the params as-is' do
        expect(parse_params).to eq('not a hash')
      end
    end
  end
end
