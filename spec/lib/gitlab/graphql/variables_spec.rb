# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Variables, feature_category: :api do
  using RSpec::Parameterized::TableSyntax

  describe 'PARSE_LIMITS' do
    it 'matches the limits from JsonValidation middleware' do
      expect(described_class::PARSE_LIMITS).to eq({
        max_depth: 32,
        max_array_size: 50000,
        max_hash_size: 50000,
        max_total_elements: 100000,
        max_json_size_bytes: 0
      })
    end
  end

  describe "MAX_RECURSION_DEPTH" do
    it "is set to 3" do
      expect(described_class::MAX_RECURSION_DEPTH).to eq(3)
    end
  end

  describe "MAX_NESTED_STRING_SIZE" do
    it "is set to 10MB" do
      expect(described_class::MAX_NESTED_STRING_SIZE).to eq(10_000_000)
    end
  end

  describe '#to_h' do
    subject(:variables) { described_class.new(param).to_h }

    context 'with valid parameters' do
      where(:description, :param, :expected) do
        'nil parameter' | nil | {}
        'empty string' | '' | {}
        'blank string' | '   ' | {}
        'empty hash' | {} | {}
        'simple hash' | { 'key' => 'value' } | { 'key' => 'value' }
        'valid JSON string' | '{"name":"test","age":30}' | { 'name' => 'test', 'age' => 30 }
        'empty JSON object' | '{}' | {}
        'nested JSON' | '{"user":{"id":1,"name":"John"}}' | { 'user' => { 'id' => 1, 'name' => 'John' } }
        'JSON with null values' | '{"value":null}' | { 'value' => nil }
        'JSON with boolean values' | '{"active":true,"disabled":false}' | { 'active' => true, 'disabled' => false }
      end

      with_them do
        it { is_expected.to eq(expected) }
      end
    end

    context 'with ActionController::Parameters' do
      let(:param) { ActionController::Parameters.new({ 'key' => 'value', 'nested' => { 'inner' => 'data' } }) }

      it 'converts to unsafe hash' do
        expect(variables).to eq({ 'key' => 'value', 'nested' => { 'inner' => 'data' } })
      end
    end

    context 'with invalid parameter types' do
      where(:param) do
        [
          123,
          [],
          Object.new,
          :symbol
        ]
      end

      with_them do
        it 'raises Invalid error' do
          expect { variables }.to raise_error(
            described_class::Invalid, "Unexpected parameter: #{param}"
          )
        end
      end
    end

    context 'with malformed JSON strings' do
      where(:json) do
        [
          '{',
          '[',
          '{"key"',
          '[1,2,3',
          '{"a":}',
          'invalid json'
        ]
      end

      with_them do
        it 'raises Invalid error' do
          expect { described_class.new(json).to_h }.to raise_error(described_class::Invalid)
        end
      end
    end

    context "when string nesting is at exactly the limit" do
      let(:json) do
        current_content = { "key" => "value" }.to_json
        3.times { current_content = current_content.to_json }
        current_content
      end

      it "parses successfully" do
        expect(described_class.new(json).to_h).to eq({ "key" => "value" })
      end
    end

    context "when the string nesting limit is exceeded" do
      let(:json) do
        current_content = { "key" => "value" }.to_json
        4.times { current_content = current_content.to_json }
        current_content
      end

      it "raises an Invalid error" do
        expect { described_class.new(json).to_h }.to raise_error(
          described_class::Invalid, "Parameters nested too deeply"
        )
      end
    end

    context "when the nesting depth is valid and the nested string is at the size limit" do
      let(:json) { { "key" => "a" * 9_999_980 }.to_json.to_json }

      it "parses successfully" do
        expect { described_class.new(json).to_h }.not_to raise_error
      end
    end

    context "when the nesting depth is valid but the nested string exceeds the size limit" do
      let(:json) { { "key" => "a" * 10_000_001 }.to_json.to_json }

      it "raises an Invalid error" do
        expect { described_class.new(json).to_h }.to raise_error(
          described_class::Invalid, "Nested parameter too large"
        )
      end
    end

    context "when a large string is at the top level (not nested)" do
      let(:json) { { "key" => "a" * 10_000_001 }.to_json }

      it "parses successfully because size limit only applies to nested strings" do
        expect { described_class.new(json).to_h }.not_to raise_error
      end
    end

    context 'when JSON exceeds limits' do
      where(:parse_limits, :json, :expected_error_message, :expected_log_message) do
        [
          [{ max_depth: 2 },
            '{"a": {"b": {"c": "too deep"}}}',
            'Parameters nested too deeply',
            'JSON depth 3 exceeds limit of 2'],
          [{ max_array_size: 2 },
            '{"items": [1, 2, 3]}',
            'Array parameter too large',
            'Array size exceeds limit of 2 (tried to add element 3)'],
          [{ max_hash_size: 2 },
            '{"a": 1, "b": 2, "c": 3}',
            'Hash parameter too large',
            'Hash size exceeds limit of 2 (tried to add key-value pair 3)'],
          [{ max_total_elements: 3 },
            '{"a": 1, "b": 2, "c": 3, "d": 4}',
            'Too many total parameters',
            'Total elements (3) exceeds limit of 3'],
          [{ max_json_size_bytes: 10 },
            '{"key": "very long value"}',
            'JSON body too large',
            'JSON body too large: 26 bytes']
        ]
      end

      with_them do
        it 'raises Invalid error with user-facing message' do
          expect { described_class.new(json, { parse_limits: parse_limits }).to_h }.to raise_error(
            described_class::Invalid, expected_error_message
          )
        end
      end
    end

    context 'with complex valid JSON within limits' do
      let(:complex_json) do
        {
          users: [
            {
              id: 1,
              name: 'Alice',
              profile: {
                email: 'alice@example.com',
                settings: {
                  theme: 'dark',
                  notifications: true
                }
              },
              tags: %w[admin user]
            },
            {
              id: 2,
              name: 'Bob',
              profile: {
                email: 'bob@example.com',
                settings: {
                  theme: 'light',
                  notifications: false
                }
              },
              tags: %w[user]
            }
          ],
          metadata: {
            total: 2,
            page: 1,
            filters: {
              active: true,
              role: 'user'
            }
          }
        }.to_json
      end

      it 'parses successfully' do
        result = described_class.new(complex_json).to_h
        expect(result).to be_a(Hash)
        expect(result['users']).to be_an(Array)
        expect(result['users'].size).to eq(2)
        expect(result['metadata']['total']).to eq(2)
      end
    end

    context 'when JSON string contains nested JSON strings' do
      let(:nested_json_string) { '{"config":"{\"nested\":true,\"value\":42}"}' }

      it 'does not parse nested JSON strings' do
        result = described_class.new(nested_json_string).to_h
        expect(result['config']).to eq('{"nested":true,"value":42}')
        expect(result['config']).to be_a(String)
      end
    end
  end
end
