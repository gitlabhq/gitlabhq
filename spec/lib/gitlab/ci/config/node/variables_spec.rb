require 'spec_helper'

describe Gitlab::Ci::Config::Node::Variables do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) do
        { 'VARIABLE_1' => 'value 1', 'VARIABLE_2' => 'value 2' }
      end

      describe '#value' do
        it 'returns hash with key value strings' do
          expect(entry.value).to eq config
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
      let(:config) { [ :VAR, 'test' ] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include /should be a hash of key value pairs/
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
