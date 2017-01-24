require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Key do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { 'test' }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq 'test'
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { [ 'incorrect' ] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'key config should be a string or symbol'
        end
      end
    end
  end
end
