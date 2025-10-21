# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Json::StreamValidator, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  describe '.user_facing_error_message' do
    subject(:error_message) { described_class.user_facing_error_message(exception_class.new) }

    where(:expected_error_message, :exception_class) do
      "Parameters nested too deeply" | described_class::DepthLimitError
      "Array parameter too large" | described_class::ArraySizeLimitError
      "Hash parameter too large" | described_class::HashSizeLimitError
      "Too many total parameters" | described_class::ElementCountLimitError
      "JSON body too large" | described_class::BodySizeExceededError
      "Invalid JSON: limit exceeded" | StandardError
    end

    with_them do
      it { is_expected.to eq(expected_error_message) }
    end
  end

  describe 'parsing valid JSON' do
    let(:options) do
      {
        max_depth: 3,
        max_array_size: 5,
        max_hash_size: 10,
        max_total_elements: 50
      }
    end

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
      validator.result
    end

    where(:description, :json, :expected) do
      'empty object'        | '{}'                                        | {}
      'empty array'         | '[]'                                        | []
      'simple object'       | '{"name":"test","age":30}'                  | { 'name' => 'test', 'age' => 30 }
      'simple array'        | '[1,2,3,4,5]'                               | [1, 2, 3, 4, 5]
      'array of strings'    | '["a","b","c"]'                             | %w[a b c]
      'nested object'       | '{"user":{"id":1,"name":"John"}}'           | { 'user' => { 'id' => 1,
                                                                                          'name' => 'John' } }
      'nested array'        | '[[1,2],[3,4]]'                             | [[1, 2], [3, 4]]
      'mixed nesting'       | '{"items":[{"id":1},{"id":2}]}'             | { 'items' => [{ 'id' => 1 },
        { 'id' => 2 }] }
      'object with null'    | '{"value":null}'                            | { 'value' => nil }
      'object with bool'    | '{"active":true,"disabled":false}'          | { 'active' => true, 'disabled' => false }
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe 'complex structure with depth limit' do
    let(:options) do
      {
        max_depth: 4,
        max_array_size: 5,
        max_hash_size: 10,
        max_total_elements: 50
      }
    end

    let(:json) { '{"users":[{"name":"Alice","tags":["admin","user"]}]}' }
    let(:expected) { { 'users' => [{ 'name' => 'Alice', 'tags' => %w[admin user] }] } }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
      validator.result
    end

    it 'parses correctly with sufficient depth' do
      expect(parse).to eq(expected)
    end
  end

  describe 'body size validation' do
    let(:options) do
      {
        max_json_size_bytes: max_json_size_bytes,
        max_depth: 0,
        max_array_size: 0,
        max_hash_size: 0,
        max_total_elements: 0
      }
    end

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:max_json_size_bytes, :json, :error_message) do
      10 | '"very long value"' | 'JSON body too large: 17 bytes'
      10 | '{"a":{"b":"c"}}' | 'JSON body too large: 15 bytes'
      20 | '{"a":{"b":{"c":"d"}}}' | 'JSON body too large: 21 bytes'
    end

    with_them do
      it 'raises BodySizeExceededError' do
        expect { parse }.to raise_error(described_class::BodySizeExceededError, error_message)
      end
    end
  end

  describe 'depth limit validation' do
    let(:options) { { max_depth: max_depth, max_array_size: 0, max_hash_size: 0, max_total_elements: 0 } }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:max_depth, :json, :error_message) do
      1 | '{"a":{"b":"c"}}' | 'JSON depth 2 exceeds limit of 1'
      2 | '{"a":{"b":{"c":"d"}}}'             | 'JSON depth 3 exceeds limit of 2'
      2 | '[[[1]]]'                           | 'JSON depth 3 exceeds limit of 2'
      3 | '{"a":{"b":{"c":{"d":"e"}}}}' | 'JSON depth 4 exceeds limit of 3'
    end

    with_them do
      it 'raises DepthLimitError' do
        expect { parse }.to raise_error(described_class::DepthLimitError, error_message)
      end
    end
  end

  describe 'array size limit validation' do
    let(:options) { { max_array_size: max_size, max_depth: 0, max_hash_size: 0, max_total_elements: 0 } }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:max_size, :json, :error_message) do
      3 | '[1,2,3,4]' | 'Array size exceeds limit of 3 (tried to add element 4)'
      5 | '[1,2,3,4,5,6]'                             | 'Array size exceeds limit of 5 (tried to add element 6)'
      2 | '{"items":["a","b","c"]}'                   | 'Array size exceeds limit of 2 (tried to add element 3)'
      4 | '[[1,2,3,4,5]]'                             | 'Array size exceeds limit of 4 (tried to add element 5)'
    end

    with_them do
      it 'raises ArraySizeLimitError' do
        expect { parse }.to raise_error(described_class::ArraySizeLimitError, error_message)
      end
    end
  end

  describe 'hash size limit validation' do
    let(:options) { { max_hash_size: max_size, max_depth: 0, max_array_size: 0, max_total_elements: 0 } }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:max_size, :json, :error_message) do
      2 | '{"a":1,"b":2,"c":3}' | 'Hash size exceeds limit of 2 (tried to add key-value pair 3)'
      3 | '{"a":1,"b":2,"c":3,"d":4}' | 'Hash size exceeds limit of 3 (tried to add key-value pair 4)'
      1 | '{"nested":{"a":1,"b":2}}' | 'Hash size exceeds limit of 1 (tried to add key-value pair 2)'
      4 | '{"a":{"b":1,"c":2,"d":3,"e":4,"f":5}}' | 'Hash size exceeds limit of 4 (tried to add key-value pair 5)'
    end

    with_them do
      it 'raises HashSizeLimitError' do
        expect { parse }.to raise_error(described_class::HashSizeLimitError, error_message)
      end
    end
  end

  describe 'total element count limit validation' do
    let(:options) { { max_total_elements: max_elements, max_depth: 0, max_array_size: 0, max_hash_size: 0 } }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:max_elements, :json, :expected_error) do
      1  | '[1,2]' | 'Total elements (1) exceeds limit of 1'
      3  | '{"a":1,"b":2}'                             | 'Total elements (3) exceeds limit of 3'
      5  | '{"a":{"b":{"c":1}}}'                       | 'Total elements (5) exceeds limit of 5'
      10 | '{"users":[{"id":1,"name":"A"},{"id":2,"name":"B"}]}' | 'Total elements (10) exceeds limit of 10'
    end

    with_them do
      it 'raises ElementCountLimitError' do
        expect { parse }.to raise_error(described_class::ElementCountLimitError, expected_error)
      end
    end
  end

  describe 'combined limits' do
    let(:options) do
      {
        max_depth: 5,
        max_array_size: 20,
        max_hash_size: 20,
        max_total_elements: 15
      }
    end

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
      validator.result
    end

    context 'when JSON is within all limits' do
      where(:json, :expected) do
        '{"data":{"items":[1,2,3],"count":3}}'  | { 'data' => { 'items' => [1, 2, 3], 'count' => 3 } }
        '[{"a":1},{"b":2},{"c":3}]'             | [{ 'a' => 1 }, { 'b' => 2 }, { 'c' => 3 }]
      end

      with_them do
        it { is_expected.to eq(expected) }
      end
    end

    context 'when JSON exceeds limits' do
      where(:json, :error_class, :error_pattern) do
        '[[[[[[1]]]]]]' | described_class::DepthLimitError | /depth 6 exceeds limit/
      end
      with_them do
        it 'raises the appropriate error' do
          expect { parse }.to raise_error(error_class, error_pattern)
        end
      end
    end
  end

  describe 'disabled limits' do
    let(:options) do
      {
        max_depth: 0,
        max_array_size: 0,
        max_hash_size: 0,
        max_total_elements: 0
      }
    end

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
      validator.result
    end

    where(:json, :expected) do
      '[[[[[[[[[[1]]]]]]]]]]' | [[[[[[[[[[1]]]]]]]]]]
      '[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]' | (1..15).to_a
      "#{'{"a":' * 50}1#{'}' * 50}" | 50.times.inject(1) { |val, _| { 'a' => val } }
    end

    with_them do
      it 'parses without errors when limits are disabled' do
        expect(parse).to eq(expected)
      end
    end
  end

  describe 'error handling for malformed JSON' do
    let(:options) { {} }

    subject(:parse) do
      validator = described_class.new(options)
      validator.sc_parse(json)
    end

    where(:json) do
      [
        '{',
        '[',
        '{"key"',
        '[1,2,3',
        '{"a":}'
      ]
    end

    with_them do
      it 'raises a parsing error' do
        expect { parse }.to raise_error do |error|
          # Could be either a Oj::ParseError or an EncodingError depending on
          # whether mimic_JSON has been called.
          expect([Oj::ParseError, EncodingError]).to include(error.class)
        end
      end
    end
  end

  describe '#metadata' do
    let(:options) do
      {
        max_depth: 10,
        max_array_size: 100,
        max_hash_size: 100,
        max_total_elements: 1000
      }
    end

    subject(:metadata) do
      validator = described_class.new(options)
      validator.sc_parse(json)
      validator.metadata
    end

    context 'with simple structures' do
      # rubocop:disable Layout/LineLength -- This is more readable
      where(:description, :json, :expected_metadata) do
        'empty object'        | '{}'                       | { body_bytesize: 2, total_elements: 1, max_array_count: 0, max_hash_count: 0, max_depth: 1 }
        'empty array'         | '[]'                       | { body_bytesize: 2, total_elements: 1, max_array_count: 0, max_hash_count: 0, max_depth: 1 }
        'simple object'       | '{"name":"test","age":30}' | { body_bytesize: 24, total_elements: 5, max_array_count: 0, max_hash_count: 2, max_depth: 1 }
        'simple array'        | '[1,2,3,4,5]'              | { body_bytesize: 11, total_elements: 6, max_array_count: 5, max_hash_count: 0, max_depth: 1 }
        'array of strings'    | '["a","b","c"]'            | { body_bytesize: 13, total_elements: 4, max_array_count: 3, max_hash_count: 0, max_depth: 1 }
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to eq(expected_metadata) }
      end
    end

    context 'with nested structures' do
      # rubocop:disable Layout/LineLength -- This is more readable
      where(:description, :json, :expected_metadata) do
        'nested object'       | '{"user":{"id":1,"name":"John"}}' | { body_bytesize: 31, total_elements: 7, max_array_count: 0, max_hash_count: 2, max_depth: 2 }
        'nested array'        | '[[1,2],[3,4]]'                   | { body_bytesize: 13, total_elements: 7, max_array_count: 2, max_hash_count: 0, max_depth: 2 }
        'mixed nesting'       | '{"items":[{"id":1},{"id":2}]}'   | { body_bytesize: 29, total_elements: 9, max_array_count: 2, max_hash_count: 1, max_depth: 3 }
        'deep nesting'        | '{"a":{"b":{"c":{"d":1}}}}'       | { body_bytesize: 25, total_elements: 9, max_array_count: 0, max_hash_count: 1, max_depth: 4 }
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to eq(expected_metadata) }
      end
    end

    context 'with complex structures' do
      let(:json) { '{"users":[{"name":"Alice","tags":["admin","user"]},{"name":"Bob","tags":["user"]}]}' }
      let(:expected_metadata) do
        {
          body_bytesize: 83,
          total_elements: 16,
          max_array_count: 2,
          max_hash_count: 2,
          max_depth: 4
        }
      end

      it { is_expected.to eq(expected_metadata) }
    end

    context 'with varying array and hash sizes' do
      let(:json) { '{"small":[1],"medium":[1,2,3],"large":[1,2,3,4,5],"hash":{"a":1,"b":2,"c":3,"d":4}}' }
      let(:expected_metadata) do
        {
          body_bytesize: 83,
          total_elements: 26,
          max_array_count: 5,
          max_hash_count: 4,
          max_depth: 2
        }
      end

      it { is_expected.to eq(expected_metadata) }
    end
  end
end
