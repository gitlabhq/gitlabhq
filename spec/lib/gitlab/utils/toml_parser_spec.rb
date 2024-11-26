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
  end
end
