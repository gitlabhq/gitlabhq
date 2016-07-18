require 'spec_helper'

describe Gitlab::Ci::Config::Node::Artifacts do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) { { paths: %w[public/] } }

      describe '#value' do
        it 'returns image string' do
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
      let(:config) { { name: 10 } }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'artifacts name should be a string'
        end
      end
    end
  end
end
