require 'spec_helper'

describe Gitlab::Ci::Config::Node::Job do
  let(:entry) { described_class.new(config, global: global) }
  let(:global) { spy('Global') }

  before do
    entry.process!
    entry.validate!
  end

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'job config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is invalid' do
            expect(entry).not_to be_valid
          end
        end
      end
    end
  end

  describe '#value' do
    context 'when entry is correct' do
      let(:config) do
        { before_script: %w[ls pwd],
          script: 'rspec' }
      end

      it 'returns correct value' do
        expect(entry.value)
          .to eq(before_script: %w[ls pwd],
                 script: 'rspec',
                 stage: 'test')
      end
    end

    context 'when entry is incorrect' do
      let(:config) { {} }

      it 'raises error' do
        expect { entry.value }.to raise_error(
          Gitlab::Ci::Config::Node::Entry::InvalidError
        )
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      expect(entry).to be_relevant
    end
  end
end
