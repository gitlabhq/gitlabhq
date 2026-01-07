# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HttpResponseParser, feature_category: :importers do
  describe '.supported_formats' do
    it 'returns the expected formats from HTTParty' do
      safe_formats = [:html, :plain]
      overridden_formats = [:csv, :json, :xml]

      expect(described_class.supported_formats).to match_array(safe_formats + overridden_formats)
    end
  end

  describe '#json' do
    let(:parsed_json) { described_class.new(body, :json).json }
    let(:body) { '{"key1": "value1", "key2": ["item1", "item2"], "key3": {"nested": "value"}}' }

    it 'parses the response body into a hash' do
      expect(parsed_json['key1']).to eq('value1')
      expect(parsed_json['key2']).to be_an(Array)
      expect(parsed_json['key2'].size).to eq(2)
      expect(parsed_json['key3']).to be_an(Hash)
      expect(parsed_json['key3'].size).to eq(1)
      expect(parsed_json['key3']['nested']).to eq('value')
    end

    context 'when body content exceeds the number of JSON structural characters' do
      before do
        stub_application_setting(max_http_response_json_structural_chars: 8)
      end

      it 'logs oversize response and raises JSON::ParserError' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          message: 'Large HTTP JSON response',
          structural_chars: 10,
          caller: anything
        )

        expect { parsed_json }.to raise_error(JSON::ParserError)
      end
    end

    context 'when max_http_response_json_structural_chars is 0' do
      before do
        stub_application_setting(max_http_response_json_structural_chars: 0)
      end

      it 'parses the response without size limit' do
        expect(parsed_json['key1']).to eq('value1')
        expect(parsed_json['key2']).to be_an(Array)
        expect(parsed_json['key3']).to be_an(Hash)
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
          expect { parsed_json }.to raise_error(JSON::ParserError)
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
          expect(parsed_json).to eq(expected)
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
          expect { parsed_json }.to raise_error(JSON::NestingError)
        end
      end

      context 'when response body does not exceed maximum depth' do
        let(:body) { { a: { b: { c: 3 } } }.to_json }

        it 'parses the response body into a hash' do
          expect(parsed_json).to eq({ "a" => { "b" => { "c" => 3 } } })
        end
      end
    end
  end

  describe '#xml' do
    subject(:parsed_xml) { described_class.new(body, :xml).xml }

    let(:body) { '<root><item>value</item></root>' }

    it 'parses the response body into a hash' do
      expect(parsed_xml).to be_a(Hash)
      expect(parsed_xml['root']).to be_a(Hash)
      expect(parsed_xml['root']['item']).to eq('value')
    end

    context 'with XML attributes' do
      let(:body) { '<root><item id="1" type="test">value</item></root>' }

      it 'parses attributes correctly' do
        expect(parsed_xml['root']['item']).to be_a(Hash)
        expect(parsed_xml['root']['item']['id']).to eq('1')
        expect(parsed_xml['root']['item']['type']).to eq('test')
        expect(parsed_xml['root']['item']['__content__']).to eq('value')
      end
    end

    context 'when body content exceeds the number of XML structural characters' do
      before do
        stub_application_setting(max_http_response_xml_structural_chars: 1)
      end

      it 'logs oversize response and raises MultiXml::ParseError' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          message: 'Large HTTP XML response',
          structural_chars: 2,
          caller: anything
        )

        expect { parsed_xml }.to raise_error(MultiXml::ParseError)
      end
    end

    context 'when max_http_response_xml_structural_chars is 0' do
      before do
        stub_application_setting(max_http_response_xml_structural_chars: 0)
      end

      it 'parses the response without size limit' do
        expect(parsed_xml).to be_a(Hash)
        expect(parsed_xml['root']).to be_a(Hash)
        expect(parsed_xml['root']['item']).to eq('value')
      end
    end
  end

  describe '#csv' do
    subject(:parsed_csv) { described_class.new(body, :csv).csv }

    let(:body) { "name,age,city\nJohn,30,NYC\nJane,25,LA" }

    it 'parses the response body into an array of arrays' do
      expect(parsed_csv).to be_an(Array)
      expect(parsed_csv.size).to eq(3)
      expect(parsed_csv[0]).to eq(%w[name age city])
      expect(parsed_csv[1]).to eq(%w[John 30 NYC])
      expect(parsed_csv[2]).to eq(%w[Jane 25 LA])
    end

    context 'with tab-separated values' do
      let(:body) { "name\tage\tcity\nJohn\t30\tNYC\nJane\t25\tLA" }

      it 'counts tabs in structural characters' do
        expect(parsed_csv).to be_an(Array)
        expect(parsed_csv.size).to eq(3)
      end
    end

    context 'with semicolon-separated values' do
      let(:body) { "name;age;city\nJohn;30;NYC\nJane;25;LA" }

      it 'counts semicolons in structural characters' do
        expect(parsed_csv).to be_an(Array)
        expect(parsed_csv.size).to eq(3)
      end
    end

    context 'when body content exceeds the number of CSV structural characters' do
      before do
        stub_application_setting(max_http_response_csv_structural_chars: 5)
      end

      it 'logs oversize response and raises CSV::MalformedCSVError with correct arguments' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          message: 'Large HTTP CSV response',
          structural_chars: 8,
          caller: anything
        )

        expect { parsed_csv }.to raise_error(CSV::MalformedCSVError) do |error|
          expect(error.message).to eq('CSV response exceeded the maximum number of objects in line 1.')
        end
      end
    end

    context 'when max_http_response_csv_structural_chars is 0' do
      before do
        stub_application_setting(max_http_response_csv_structural_chars: 0)
      end

      it 'parses the response without size limit' do
        expect(parsed_csv).to be_an(Array)
        expect(parsed_csv.size).to eq(3)
        expect(parsed_csv[0]).to eq(%w[name age city])
        expect(parsed_csv[1]).to eq(%w[John 30 NYC])
        expect(parsed_csv[2]).to eq(%w[Jane 25 LA])
      end
    end
  end

  describe 'private methods' do
    let(:parser) { described_class.new('{}', :json) }

    describe '#total_structural_chars_for' do
      it 'raises ArgumentError for unsupported type' do
        expect { parser.send(:total_structural_chars_for, :unsupported) }
          .to raise_error(ArgumentError, 'Unsupported type: unsupported')
      end
    end

    describe '#max_structural_chars_for' do
      it 'raises ArgumentError for unsupported type' do
        expect { parser.send(:max_structural_chars_for, :unsupported) }
          .to raise_error(ArgumentError, 'Unsupported type: unsupported')
      end
    end

    describe '#oversize_response_error_for' do
      it 'raises ArgumentError for unsupported type' do
        expect { parser.send(:oversize_response_error_for, :unsupported) }
          .to raise_error(ArgumentError, 'Unsupported type: unsupported')
      end
    end
  end
end
