# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::Mount do
  subject(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'with a valid config' do
      context 'and target is a non-empty string' do
        let(:config) do
          {
            source: 'source',
            target: 'sub-site'
          }
        end

        it { is_expected.to be_valid }

        describe '#value' do
          it 'returns mount configuration' do
            expect(entry.value).to eq config
          end
        end
      end

      context 'and target is an empty string' do
        let(:config) do
          {
            source: 'source',
            target: ''
          }
        end

        it { is_expected.to be_valid }

        describe '#value' do
          it 'returns mount configuration' do
            expect(entry.value).to eq config
          end
        end
      end
    end

    context 'with an invalid config' do
      context 'when source is not a string' do
        let(:config) { { source: 123, target: 'target' } }

        it { is_expected.not_to be_valid }

        it 'reports error' do
          expect(entry.errors)
            .to include 'mount source should be a string'
        end
      end

      context 'when source is not present' do
        let(:config) { { target: 'target' } }

        it { is_expected.not_to be_valid }

        it 'reports error' do
          expect(entry.errors)
            .to include "mount source can't be blank"
        end
      end

      context 'when target is not a string' do
        let(:config) { { source: 'source', target: 123 } }

        it { is_expected.not_to be_valid }

        it 'reports error' do
          expect(entry.errors)
            .to include 'mount target should be a string'
        end
      end

      context 'when there is an unknown key present' do
        let(:config) { { test: 100 } }

        it { is_expected.not_to be_valid }

        it 'reports error' do
          expect(entry.errors)
            .to include 'mount config contains unknown keys: test'
        end
      end
    end
  end

  describe '.default' do
    it 'returns default mount' do
      expect(described_class.default)
        .to eq({
                 source: 'source',
                 target: ''
               })
    end
  end
end
