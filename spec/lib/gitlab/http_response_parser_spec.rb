# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HttpResponseParser, feature_category: :importers do
  describe '#json' do
    let(:json_parser) { described_class.new(body, :json).json }
    let(:body) { '{"key1": "value1", "key2": ["item1", "item2"], "key3": {"nested": "value"}}' }

    it 'parses the response body into a hash' do
      result = json_parser

      expect(result['key1']).to eq('value1')
      expect(result['key2']).to be_an(Array)
      expect(result['key2'].size).to eq(2)
      expect(result['key3']).to be_an(Hash)
      expect(result['key3'].size).to eq(1)
      expect(result['key3']['nested']).to eq('value')
    end

    context 'when body content exceeds the number of JSON structural characters' do
      before do
        stub_application_setting(max_http_response_json_structural_chars: 8)
      end

      it 'logs oversize response and raises JSON::ParserError' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          message: 'Large HTTP JSON response',
          number_of_fields: 10,
          caller: anything
        )

        expect { json_parser }.to raise_error(JSON::ParserError)
      end
    end

    context 'with malformed JSON strings' do
      where(:body) do
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
          expect { json_parser }.to raise_error(JSON::ParserError)
        end
      end
    end

    context 'with literal strings' do
      where(:body, :expected) do
        [
          ['true', true],
          ['false', false],
          ['null', nil],
          ["123", 123],
          ["-123", -123],
          ["-1.23", -1.23],
          ["-1.23e10", -12300000000.0],
          ["-1.23E-1", -1.23e-1],
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
          expect(json_parser).to eq(expected)
        end
      end
    end

    describe 'maximum depth' do
      before do
        stub_application_setting(max_http_response_json_depth: 3)
      end

      context 'when response body exceeds maximum depth' do
        let(:body) { { a: { b: { c: { d: 1 } } } }.to_json }

        it 'raises JSON::NestingError' do
          expect { json_parser }.to raise_error(JSON::NestingError)
        end
      end

      context 'when response body does not exceed maximum depth' do
        let(:body) { { a: { b: { c: 3 } } }.to_json }

        it 'parses the response body into a hash' do
          result = json_parser

          expect(result).to eq({ "a" => { "b" => { "c" => 3 } } })
        end
      end
    end
  end
end
