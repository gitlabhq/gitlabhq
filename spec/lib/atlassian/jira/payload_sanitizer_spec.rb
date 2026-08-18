# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Jira::PayloadSanitizer, feature_category: :integrations do
  let(:nul) { [0x0].pack('U') } # control char, rejected by Atlassian
  let(:emoji) { '🚝' } # astral char, rejected by Atlassian

  describe '.sanitize' do
    it 'removes rejected characters but keeps valid ones' do
      aggregate_failures do
        expect(described_class.sanitize("a#{emoji}b#{nul}c")).to eq('abc')
        expect(described_class.sanitize('café ñ')).to eq('café ñ')
      end
    end

    it 'recurses into arrays and hashes and leaves non-strings untouched' do
      input = { 'name' => "x#{emoji}", 'list' => ["y#{nul}", 1, nil, true] }

      expect(described_class.sanitize(input)).to eq({ 'name' => 'x', 'list' => ['y', 1, nil, true] })
    end

    it 'substitutes U+FFFD when stripping would empty a non-empty string' do
      aggregate_failures do
        expect(described_class.sanitize(emoji)).to eq("\u{FFFD}")
        expect(described_class.sanitize('')).to eq('')
      end
    end

    context 'when the payload exceeds SafeParser limits' do
      let(:payload) { { 'name' => "x#{emoji}" } }

      before do
        allow(Gitlab::Json::SafeParser).to receive(:parse).and_raise(JSON::ParserError, 'JSON body too large')
      end

      it 'tracks the exception and falls back to the unsanitized payload' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(JSON::ParserError))

        expect(described_class.sanitize(payload)).to eq(payload)
      end
    end
  end
end
