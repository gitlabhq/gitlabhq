# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Assets::JsCompressor, feature_category: :internationalization do
  let(:data) { 'window.translations = {"domain":"app"};' }

  describe '.call' do
    it 'returns locale bundles unchanged' do
      input = { filename: '/builds/gitlab/app/assets/javascripts/locale/de/app.js', data: data }

      expect(Terser::Compressor).not_to receive(:call)
      expect(described_class.call(input)).to eq(data)
    end

    it 'compresses every other javascript asset' do
      input = { filename: '/builds/gitlab/app/assets/javascripts/main.js', data: data }

      expect(Terser::Compressor).to receive(:call).with(input).and_return('compressed')
      expect(described_class.call(input)).to eq('compressed')
    end

    it 'compresses javascript that merely lives under a locale directory' do
      input = { filename: '/builds/gitlab/app/assets/javascripts/locale/index.js', data: data }

      expect(Terser::Compressor).to receive(:call).with(input).and_return('compressed')
      expect(described_class.call(input)).to eq('compressed')
    end
  end

  describe '.cache_key' do
    it 'does not collide with the plain Terser cache key' do
      expect(described_class.cache_key).not_to eq(Terser::Compressor.cache_key)
    end
  end
end
