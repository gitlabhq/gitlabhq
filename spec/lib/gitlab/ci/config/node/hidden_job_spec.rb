require 'spec_helper'

describe Gitlab::Ci::Config::Node::HiddenJob do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { { image: 'ruby:2.2' } }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(image: 'ruby:2.2')
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
              .to include 'hidden job config should be a hash'
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
