require 'spec_helper'

describe Gitlab::Ci::Config::Node::Job do
  let(:entry) { described_class.new(config, global: global) }
  let(:global) { spy('Global') }

  describe 'validations' do
    before do
      entry.process!
      entry.validate!
    end

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value)
            .to eq(script: 'rspec',
                   stage: 'test')
        end
      end

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
          it 'saves errors' do
            expect(entry.errors)
              .to include 'job config should be a hash'
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      expect(entry).to be_relevant
    end
  end
end
