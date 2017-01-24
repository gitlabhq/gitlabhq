require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Image do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) { 'ruby:2.2' }

      describe '#value' do
        it 'returns image string' do
          expect(entry.value).to eq 'ruby:2.2'
        end
      end

      describe '#errors' do
        it 'does not append errors' do
          expect(entry.errors).to be_empty
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { ['ruby:2.2'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'image config should be a string'
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
