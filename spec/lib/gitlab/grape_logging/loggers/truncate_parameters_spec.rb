# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::TruncateParameters, feature_category: :observability do
  subject(:logger) { described_class.new }

  let(:env) { { 'rack.input' => '' } }
  let(:mock_request) { ActionDispatch::Request.new(env) }
  let(:response_body) { nil }

  describe '#parameters' do
    context 'when request has no params' do
      it 'returns empty hash' do
        expect(logger.parameters(mock_request, response_body)).to eq({})
      end
    end

    context 'when request has params' do
      before do
        mock_request.params['key1'] = 'value1'
        mock_request.params['key2'] = 'value2'
      end

      it 'returns empty hash as it modifies request params in place' do
        expect(logger.parameters(mock_request, response_body)).to eq({})
      end

      it 'encodes UTF-8 values' do
        mock_request.params['utf8_key'] = (+"test\xC0").force_encoding('ASCII-8BIT')

        logger.parameters(mock_request, response_body)

        expect(mock_request.params['utf8_key']).to be_valid_encoding
      end
    end

    context 'with nested hash parameters' do
      before do
        mock_request.params['user'] = {
          'name' => (+"test\xC0").force_encoding('ASCII-8BIT'),
          'email' => 'test@example.com'
        }
        mock_request.params['simple'] = 'value'
      end

      it 'encodes UTF-8 values in nested hashes' do
        logger.parameters(mock_request, response_body)

        expect(mock_request.params['user']['name']).to be_valid_encoding
        expect(mock_request.params['user']['email']).to eq('test@example.com')
        expect(mock_request.params['simple']).to eq('value')
      end
    end

    context 'with array parameters' do
      before do
        mock_request.params['tags'] = ['tag1', (+"tag2\xC0").force_encoding('ASCII-8BIT'), 'tag3']
        mock_request.params['simple'] = 'value'
      end

      it 'encodes UTF-8 values in arrays' do
        logger.parameters(mock_request, response_body)

        expect(mock_request.params['tags'][0]).to eq('tag1')
        expect(mock_request.params['tags'][1]).to be_valid_encoding
        expect(mock_request.params['tags'][2]).to eq('tag3')
        expect(mock_request.params['simple']).to eq('value')
      end
    end

    context 'with mixed data types' do
      before do
        mock_request.params['string'] = 'test'
        mock_request.params['integer'] = 123
        mock_request.params['float'] = 45.67
        mock_request.params['boolean'] = true
        mock_request.params['nil_value'] = nil
        mock_request.params['array'] = [1, 'two', nil]
        mock_request.params['hash'] = { 'nested' => 'value' }
      end

      it 'handles various data types correctly' do
        logger.parameters(mock_request, response_body)

        expect(mock_request.params['string']).to eq('test')
        expect(mock_request.params['integer']).to eq(123)
        expect(mock_request.params['float']).to eq(45.67)
        expect(mock_request.params['boolean']).to be true
        expect(mock_request.params['nil_value']).to be_nil
        expect(mock_request.params['array']).to eq([1, 'two', nil])
        expect(mock_request.params['hash']).to eq({ 'nested' => 'value' })
      end
    end
  end
end
