require 'spec_helper'

describe Gitlab::Ci::Config::Node::Stage do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { :stage1 }

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

      context 'when entry config is incorrect' do
        let(:config) { { test: true } }

        describe '#errors' do
          it 'reports errors' do
            expect(entry.errors)
              .to include 'stage config should be a string or symbol'
          end
        end

        describe '#valid?' do
          it 'is not valid' do
            expect(entry).not_to be_valid
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
