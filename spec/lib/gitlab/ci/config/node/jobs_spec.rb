require 'spec_helper'

describe Gitlab::Ci::Config::Node::Jobs do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { { rspec: { script: 'rspec' } } }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(rspec: { script: 'rspec' })
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
              .to include 'jobs config should be a hash'
          end
        end
      end
    end
  end
end
