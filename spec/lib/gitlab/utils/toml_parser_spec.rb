# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::TomlParser, feature_category: :source_code_management do
  let(:result) { described_class.safe_parse(content) }
  let(:content) { 'key = "value"' }

  describe '.safe_parse' do
    context 'when TOML content is valid' do
      it 'parses the content correctly' do
        expect(result).to eq({ 'key' => 'value' })
      end
    end

    context 'when TOML content is invalid' do
      let(:content) { 'invalid_toml' }

      it 'raises a ParserError' do
        expect { result }.to raise_error(Gitlab::Utils::TomlParser::ParseError, 'content is not valid TOML')
      end
    end

    context 'with timeout' do
      let(:content) do
        "data = \")'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\\)'\n"
      end

      before do
        stub_const("#{described_class}::PARSE_TIMEOUT", 0.1)
      end

      it 'times out when parsing takes too long' do
        expect(Timeout).to receive(:timeout).and_call_original
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(Timeout::Error))

        expect { result }.to raise_error(Gitlab::Utils::TomlParser::ParseError, 'timeout while parsing TOML')
      end
    end

    context 'with error raised by TomlRB' do
      context 'with TomlRB::ValueOverwriteError' do
        let(:content) do
          <<~TOML
            rust.unused_must_use = "deny"
            rust.rust_2018_idioms = { level = "deny", priority = -1 }
          TOML
        end

        it 'raises a ParserError with the error message' do
          error_message = 'error parsing TOML: Key "rust" is defined more than once'
          expect { result }.to raise_error(Gitlab::Utils::TomlParser::ParseError, error_message)
        end
      end

      context 'with unexpected TomlRB errors' do
        let(:future_error) { Class.new(TomlRB::Error) }

        before do
          allow(TomlRB).to receive(:parse).and_raise(future_error.new("Unexpected error"))
        end

        it 'raises a ParserError with the error message' do
          error_message = 'error parsing TOML: Unexpected error'
          expect { result }.to raise_error(Gitlab::Utils::TomlParser::ParseError, error_message)
        end
      end
    end
  end
end
