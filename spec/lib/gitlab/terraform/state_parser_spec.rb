# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Terraform::StateParser, feature_category: :infrastructure_as_code do
  describe '.extract_serial' do
    context 'with valid JSON containing serial' do
      it 'extracts serial from simple JSON' do
        json_data = '{"serial": 42, "version": 4}'

        expect(described_class.extract_serial(json_data)).to eq(42)
      end

      it 'extracts serial from complex nested JSON' do
        json_data = {
          "version" => 4,
          "terraform_version" => "1.0.0",
          "serial" => 123,
          "lineage" => "abc-123",
          "outputs" => {},
          "resources" => [
            {
              "mode" => "managed",
              "type" => "aws_instance",
              "name" => "example",
              "provider" => "provider[\"registry.terraform.io/hashicorp/aws\"]",
              "instances" => []
            }
          ]
        }.to_json

        expect(described_class.extract_serial(json_data)).to eq(123)
      end

      it 'extracts serial when it appears early in JSON' do
        json_data = "{\"serial\": 1, \"large_data\": \"#{'x' * 10000}\"}"

        expect(described_class.extract_serial(json_data)).to eq(1)
      end

      it 'extracts serial when it appears late in JSON' do
        json_data = "{\"large_data\": \"#{'x' * 10000}\", \"serial\": 999}"

        expect(described_class.extract_serial(json_data)).to eq(999)
      end

      it 'handles string serial values' do
        json_data = '{"serial": "42", "version": 4}'

        expect(described_class.extract_serial(json_data)).to eq("42")
      end

      it 'handles zero serial value' do
        json_data = '{"serial": 0, "version": 4}'

        expect(described_class.extract_serial(json_data)).to eq(0)
      end

      it 'handles negative serial value' do
        json_data = '{"serial": -1, "version": 4}'

        expect(described_class.extract_serial(json_data)).to eq(-1)
      end
    end

    context 'with valid JSON without serial' do
      it 'returns nil when serial is not present' do
        json_data = '{"version": 4, "terraform_version": "1.0.0"}'

        expect(described_class.extract_serial(json_data)).to be_nil
      end

      it 'returns nil for empty JSON object' do
        json_data = '{}'

        expect(described_class.extract_serial(json_data)).to be_nil
      end

      it 'ignores nested serial keys' do
        json_data = '{"metadata": {"serial": 999}, "version": 4}'

        expect(described_class.extract_serial(json_data)).to be_nil
      end

      it 'ignores serial in arrays' do
        json_data = '{"items": [{"serial": 123}], "version": 4}'

        expect(described_class.extract_serial(json_data)).to be_nil
      end
    end

    context 'with invalid JSON' do
      it 'raises JSON::ParserError for malformed JSON that contains serial' do
        invalid_json = '{"serial": 42, "version":'

        expect { described_class.extract_serial(invalid_json) }
          .to raise_error(JSON::ParserError)
      end

      it 'raises JSON::ParserError for completely invalid JSON' do
        invalid_json = 'not json at all'

        expect { described_class.extract_serial(invalid_json) }
          .to raise_error(JSON::ParserError)
      end

      it 'raises JSON::ParserError for empty string' do
        expect { described_class.extract_serial('') }
          .to raise_error(JSON::ParserError)
      end

      it 'raises JSON::ParserError for nil input' do
        expect { described_class.extract_serial(nil) }
          .to raise_error(JSON::ParserError, /Nil is not a valid JSON source/)
      end
    end

    context 'with encoding issues' do
      it 'raises JSON::ParserError for invalid UTF-8' do
        invalid_utf8 = (+"\xFF\xFE{'serial': 42}").force_encoding('UTF-8')

        expect { described_class.extract_serial(invalid_utf8) }
          .to raise_error(JSON::ParserError)
      end
    end
  end
end
