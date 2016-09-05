require 'spec_helper'

describe Gitlab::Ci::Config::Node::Hidden do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { [:some, :array] }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq [:some, :array]
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
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

  describe '#leaf?' do
    it 'is a leaf' do
      expect(entry).to be_leaf
    end
  end

  describe '#relevant?' do
    it 'is not a relevant entry' do
      expect(entry).not_to be_relevant
    end
  end
end
