# frozen_string_literal: true

require 'spec_helper'

# We can disable the cop that enforces the use of this class
# as we need to test around it.
#
RSpec.describe Gitlab::Json, feature_category: :shared do
  describe '.safe_parse' do
    it 'uses Gitlab::Json::StreamValidator to validate the limits' do
      string = '{"name":"test","age":30}'

      expect_next_instance_of(Gitlab::Json::StreamValidator, described_class::PARSE_LIMITS) do |validator|
        expect(validator).to receive(:validate!).with(string)
      end

      subject.safe_parse(string)
    end

    it 'merges parse_limits with defaults' do
      string = '{"name":"test","age":30}'
      parse_limits = { max_depth: 5, max_json_size_bytes: 100 }

      expected_limits = described_class::PARSE_LIMITS.merge(parse_limits)
      expect_next_instance_of(Gitlab::Json::StreamValidator, expected_limits) do |validator|
        expect(validator).to receive(:validate!).with(string)
      end

      subject.safe_parse(string, parse_limits: parse_limits)
    end

    context 'when the string is nil' do
      it 'returns nil' do
        expect(subject.safe_parse(nil)).to be_nil
      end
    end

    context 'with malformed JSON strings' do
      where(:string) do
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
        it 'raises JSON::ParserError' do
          expect { subject.safe_parse(string) }.to raise_error(JSON::ParserError)
        end
      end
    end

    context 'with valid JSON strings' do
      where(:json, :expected) do
        [
          ['{}', {}],
          ['[]', []],
          ['{"name":"test","age":30}', { 'name' => 'test', 'age' => 30 }],
          ['[1,2,3,4,5]', [1, 2, 3, 4, 5]],
          ['["a","b","c"]', %w[a b c]],
          ['[[1,2],[3,4]]', [[1, 2], [3, 4]]],
          ['{"items":[{"id":1},{"id":2}]}', { 'items' => [{ 'id' => 1 }, { 'id' => 2 }] }],
          ['{"value":null}', { 'value' => nil }],
          ['{"a": {"b": {"c": "nested"}}}', { "a" => { "b" => { "c" => "nested" } } }]
        ]
      end

      with_them do
        it 'parses the JSON string' do
          expect(subject.safe_parse(json)).to eq(expected)
        end
      end
    end

    context 'with literal strings' do
      where(:string, :expected) do
        [
          ['true', true],
          ['false', false],
          ['null', nil],
          ["123", 123],
          ["-123", -123],
          ["-1.23", -1.23],
          ["-1.23e10", -12300000000.0],
          ["-1.23E-1", -1.23e-1],
          ["1.5E1000", Float::INFINITY],
          ['"simple"', 'simple'],
          ['"hello world"', 'hello world'],
          ['""', ''],
          ['"say \\"hello\\""', 'say "hello"'],
          ['"backslash: \\\\"', 'backslash: \\'],
          ['"forward slash: \\/"', 'forward slash: /'],
          ['"line1\\nline2"', "line1\nline2"],
          ['"tab\\there"', "tab\there"],
          ['"carriage\\rreturn"', "carriage\rreturn"],
          ['"backspace\\bhere"', "backspace\bhere"],
          ['"form\\ffeed"', "form\ffeed"],
          ['"unicode: \\u0041"', 'unicode: A'],
          ['"unicode: \\u00E9"', 'unicode: é'],
          ['"unicode: \\u20AC"', 'unicode: €'],
          ['"mixed: \\u0048\\u0065\\u006C\\u006C\\u006F"', 'mixed: Hello'],
          ['"complex: \\"Hello\\nWorld\\" \\u2764"', "complex: \"Hello\nWorld\" ❤"],
          ['"all escapes: \\"\\\\\\/ \\b\\f\\n\\r\\t \\u0041"', "all escapes: \"\\/\s\b\f\n\r\t A"]
        ]
      end

      with_them do
        it 'parses literal strings' do
          expect(subject.safe_parse(string)).to eq(expected)
        end
      end
    end

    context 'when literal string exceeds max_json_size_bytes' do
      it 'raises JSON::ParserError' do
        string = "\"#{'a' * 10}\""

        expect { subject.safe_parse(string, parse_limits: { max_json_size_bytes: 5 }) }
          .to raise_error(JSON::ParserError, 'JSON body too large')
      end
    end

    context 'when JSON exceeds limits' do
      where(:parse_limits, :string, :expected_error_message, :expected_log_message, :expected_exception_class) do
        [
          [{ max_depth: 2 },
            '{"a": {"b": {"c": "too deep"}}}',
            'Parameters nested too deeply',
            'JSON depth 3 exceeds limit of 2',
            'Gitlab::Json::StreamValidator::DepthLimitError'],
          [{ max_array_size: 2 },
            '{"items": [1, 2, 3]}',
            'Array parameter too large',
            'Array size exceeds limit of 2 (tried to add element 3)',
            'Gitlab::Json::StreamValidator::ArraySizeLimitError'],
          [{ max_hash_size: 2 },
            '{"a": 1, "b": 2, "c": 3}',
            'Hash parameter too large',
            'Hash size exceeds limit of 2 (tried to add key-value pair 3)',
            'Gitlab::Json::StreamValidator::HashSizeLimitError'],
          [{ max_total_elements: 3 },
            '{"a": 1, "b": 2, "c": 3, "d": 4}',
            'Too many total parameters',
            'Total elements (3) exceeds limit of 3',
            'Gitlab::Json::StreamValidator::ElementCountLimitError'],
          [{ max_json_size_bytes: 10 },
            '{"key": "very long value"}',
            'JSON body too large',
            'JSON body too large: 26 bytes',
            'Gitlab::Json::StreamValidator::BodySizeExceededError']
        ]
      end

      with_them do
        it 'raises JSON::ParserError error with user-facing message' do
          allow(Gitlab::AppLogger).to receive(:warn)

          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              message: 'Exceeded allowed limits for parsing JSON input',
              parse_limits: hash_including(parse_limits),
              'exception.backtrace' => anything,
              'exception.class' => expected_exception_class,
              'exception.message' => expected_log_message
            )
          )

          expect { subject.safe_parse(string, { parse_limits: parse_limits }) }
            .to raise_error(JSON::ParserError, expected_error_message)
        end
      end
    end
  end
end
