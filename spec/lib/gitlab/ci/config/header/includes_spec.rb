# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Includes, feature_category: :pipeline_composition do
  let(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  describe 'validations' do
    context 'when configuration is an array of hashes' do
      let(:config) do
        [
          { local: 'path/to/file1.yml' },
          { local: 'path/to/file2.yml' }
        ]
      end

      it 'is valid' do
        expect(entry).to be_valid
        expect(entry.errors).to be_empty
      end

      it 'returns the value' do
        expect(entry.value).to eq(config)
      end
    end

    context 'when configuration contains invalid include entry' do
      let(:config) do
        [
          { local: 'path/to/file1.yml' },
          { random: 'https://example.com/file.yml' }
        ]
      end

      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'returns appropriate error' do
        expect(entry.errors).to include('include config contains unknown keys: random')
      end
    end

    context 'when configuration is a string' do
      let(:config) { 'path/to/file.yml' }

      it 'is valid' do
        expect(entry).to be_valid
        expect(entry.errors).to be_empty
      end

      it 'returns the value as an array' do
        expect(entry.value).to eq([config])
      end
    end

    context 'when configuration is a hash' do
      let(:config) { { local: 'path/to/file.yml' } }

      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'returns appropriate error' do
        expect(entry.errors).to include('includes config should be an array or a string')
      end
    end

    context 'when configuration is not array or string' do
      let(:config) { 123 }

      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'returns appropriate error' do
        expect(entry.errors).to include('includes config should be an array or a string')
      end
    end

    context 'when configuration is nil' do
      let(:config) { nil }

      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'returns appropriate error' do
        expect(entry.errors).to include('includes config should be an array or a string')
      end
    end
  end

  describe '#composable_class' do
    let(:config) { [{ local: 'path/to/file.yml' }] }

    it 'returns Header::Include class' do
      expect(entry.composable_class).to eq(Gitlab::Ci::Config::Header::Include)
    end
  end
end
