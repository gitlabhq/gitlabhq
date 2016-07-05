require 'spec_helper'

describe Gitlab::Ci::Config::Node::Services do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { ['postgres:9.1', 'mysql:5.5'] }

      describe '#value' do
        it 'returns array of services as is' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { 'ls' }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'services config should be an array of strings'
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
