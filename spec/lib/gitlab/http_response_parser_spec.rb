# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HttpResponseParser, feature_category: :importers do
  let(:parser) { described_class.new(body, format) }
  let(:format) { :json }
  let(:body) { '{"key1": "value1", "key2": ["item1", "item2"], "key3": {"nested": "value"}}' }

  describe '#json' do
    shared_examples 'parses json without logging' do
      it 'parses json without logging' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        result = parser.json
        expect(result['key1']).to eq('value1')
      end
    end

    shared_examples 'parses json with logging' do |expected_fields_count|
      it 'logs oversize response and parses json' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: 'Large HTTP JSON response',
          number_of_fields: expected_fields_count,
          caller: anything
        )

        result = parser.json
        expect(result['key1']).to eq('value1')
      end
    end

    context 'when response is not oversize' do
      before do
        stub_env('GITLAB_JSON_SIZE_THRESHOLD', '100')
      end

      it_behaves_like 'parses json without logging'
    end

    context 'when response is oversize' do
      before do
        stub_env('GITLAB_JSON_SIZE_THRESHOLD', '5')
      end

      it_behaves_like 'parses json with logging', 10
    end

    context 'when threshold environment variable is 0' do
      before do
        stub_env('GITLAB_JSON_SIZE_THRESHOLD', '0')
      end

      it_behaves_like 'parses json without logging'
    end

    context 'when threshold environment variable is not defined' do
      it_behaves_like 'parses json without logging'
    end
  end
end
