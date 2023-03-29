# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Publish, feature_category: :pages do
  let(:publish) { described_class.new(config) }

  describe 'validations' do
    context 'when publish config value is correct' do
      let(:config) { 'dist/static' }

      describe '#config' do
        it 'returns the publish directory' do
          expect(publish.config).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(publish).to be_valid
        end
      end
    end

    context 'when the value has a wrong type' do
      let(:config) { { test: true } }

      it 'reports an error' do
        expect(publish.errors)
          .to include 'publish config should be a string'
      end
    end
  end

  describe '.default' do
    it 'returns the default value' do
      expect(described_class.default).to eq 'public'
    end
  end
end
