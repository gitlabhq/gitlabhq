# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig do
  let(:config) do
    described_class.new(yml)
  end

  context 'when config is valid' do
    context 'when config has valid values' do
      let(:yml) do
        <<-EOS
        static_site_generator: middleman
        EOS
      end

      describe '#to_hash_with_defaults' do
        it 'returns hash created from string' do
          expect(config.to_hash_with_defaults.fetch(:static_site_generator)).to eq 'middleman'
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(config).to be_valid
        end

        it 'has no errors' do
          expect(config.errors).to be_empty
        end
      end
    end
  end

  context 'when a config entry has an empty value' do
    let(:yml) { 'static_site_generator: ' }

    describe '#to_hash' do
      it 'returns default value' do
        expect(config.to_hash_with_defaults.fetch(:static_site_generator)).to eq 'middleman'
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(config).to be_valid
      end

      it 'has no errors' do
        expect(config.errors).to be_empty
      end
    end
  end

  context 'when config is invalid' do
    context 'when yml is incorrect' do
      let(:yml) { '// invalid' }

      describe '.new' do
        it 'raises error' do
          expect { config }.to raise_error(described_class::ConfigError, /Invalid configuration format/)
        end
      end
    end

    context 'when config value exists but is not a valid value' do
      let(:yml) { 'static_site_generator: "unsupported-generator"' }

      describe '#valid?' do
        it 'is not valid' do
          expect(config).not_to be_valid
        end

        it 'has errors' do
          expect(config.errors).not_to be_empty
        end
      end

      describe '#errors' do
        it 'returns an array of strings' do
          expect(config.errors).to all(be_an_instance_of(String))
        end
      end
    end
  end
end
