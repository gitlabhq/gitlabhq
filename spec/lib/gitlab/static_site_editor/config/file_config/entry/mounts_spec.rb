# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::Mounts do
  subject(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'with a valid config' do
      let(:config) do
        [
          {
            source: 'source',
            target: ''
          },
          {
            source: 'sub-site/source',
            target: 'sub-site'
          }
        ]
      end

      it { is_expected.to be_valid }

      describe '#value' do
        it 'returns mounts configuration' do
          expect(entry.value).to eq config
        end
      end
    end

    context 'with an invalid config' do
      let(:config) { { not_an_array: true } }

      it { is_expected.not_to be_valid }

      it 'reports errors about wrong type' do
        expect(entry.errors)
          .to include 'mounts config should be a array'
      end
    end
  end

  describe '.default' do
    it 'returns default mounts' do
      expect(described_class.default)
        .to eq([{
                 source: 'source',
                 target: ''
               }])
    end
  end
end
