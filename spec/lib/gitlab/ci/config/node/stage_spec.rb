require 'spec_helper'

describe Gitlab::Ci::Config::Node::Stage do
  let(:entry) { described_class.new(config, global: global) }
  let(:global) { spy('Global') }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { :build }

      describe '#value' do
        it 'returns a stage key' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry config is incorrect' do
      describe '#errors' do
        context 'when reference to global node is not set' do
          let(:entry) { described_class.new(config) }

          it 'raises error' do
            expect { entry }
              .to raise_error Gitlab::Ci::Config::Node::Entry::InvalidError
          end
        end

        context 'when value has a wrong type' do
          let(:config) { { test: true } }

          it 'reports errors about wrong type' do
            expect(entry.errors)
              .to include 'stage config should be a string or symbol'
          end
        end

        context 'when stage is not present in global configuration' do
          pending 'reports error about missing stage' do
            expect(entry.errors)
              .to include 'stage config should be one of test, stage'
          end
        end
      end
    end
  end

  describe '.default' do
    it 'returns default stage' do
      expect(described_class.default).to eq :test
    end
  end
end
