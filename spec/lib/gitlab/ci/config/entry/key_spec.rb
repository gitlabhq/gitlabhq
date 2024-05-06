# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Key do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    it_behaves_like 'key entry validations', 'simple key'

    context 'when entry config value is correct' do
      context 'when key is a hash' do
        let(:config) { { files: ['test'], prefix: 'something' } }

        describe '#value' do
          it 'returns key value' do
            expect(entry.value).to match(config)
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when key is a symbol' do
        let(:config) { :key }

        describe '#value' do
          it 'returns key value' do
            expect(entry.value).to eq(config.to_s)
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { ['incorrect'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors.first)
            .to match(/should be a hash, a string or a symbol/)
        end
      end
    end
  end

  describe '.default' do
    it 'returns default key' do
      expect(described_class.default).to eq 'default'
    end
  end
end
