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

  describe '#xml' do
    let(:xml_parser) { described_class.new(body, :xml).xml }
    let(:body) { '<root><item>value</item></root>' }

    it 'parses the response body into a hash' do
      result = xml_parser

      expect(result).to be_a(Hash)
      expect(result['root']).to be_a(Hash)
      expect(result['root']['item']).to eq('value')
    end

    it 'logs the parse method call with the number of angle brackets' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        message: 'HttpResponseParser method called',
        parse_method: :xml,
        structural_element_count: 2,
        caller: anything
      )

      xml_parser
    end

    context 'with XML attributes' do
      let(:body) { '<root><item id="1" type="test">value</item></root>' }

      it 'parses attributes correctly' do
        result = xml_parser

        expect(result['root']['item']).to be_a(Hash)
        expect(result['root']['item']['id']).to eq('1')
        expect(result['root']['item']['type']).to eq('test')
        expect(result['root']['item']['__content__']).to eq('value')
      end

      it 'logs the parse method call with the number of angle brackets' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: 'HttpResponseParser method called',
          parse_method: :xml,
          structural_element_count: 4,
          caller: anything
        )

        xml_parser
      end
    end
  end

  describe '#csv' do
    let(:csv_parser) { described_class.new(body, :csv).csv }
    let(:body) { "name,age,city\nJohn,30,NYC\nJane,25,LA" }

    it 'parses the response body into an array of arrays' do
      result = csv_parser

      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result[0]).to eq(%w[name age city])
      expect(result[1]).to eq(%w[John 30 NYC])
      expect(result[2]).to eq(%w[Jane 25 LA])
    end

    it 'logs the parse method call with the number of commas and newlines' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        message: 'HttpResponseParser method called',
        parse_method: :csv,
        structural_element_count: 8,
        caller: anything
      )

      csv_parser
    end

    context 'with semicolon-separated values' do
      let(:body) { "name;age;city\nJohn;30;NYC\nJane;25;LA" }

      it 'parses semicolon-separated CSV correctly' do
        result = csv_parser

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0]).to eq(['name;age;city'])
        expect(result[1]).to eq(['John;30;NYC'])
      end

      it 'counts only newlines when no commas present' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: 'HttpResponseParser method called',
          parse_method: :csv,
          structural_element_count: 2,
          caller: anything
        )

        csv_parser
      end
    end
  end
end
