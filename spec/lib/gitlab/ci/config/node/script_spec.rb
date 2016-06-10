require 'spec_helper'

describe Gitlab::Ci::Config::Node::Script do
  let(:entry) { described_class.new(value) }

  describe '#validate!' do
    before { entry.validate! }

    context 'when entry value is correct' do
      let(:value) { ['ls', 'pwd'] }

      describe '#value' do
        it 'returns concatenated command' do
          expect(entry.value).to eq "ls\npwd"
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
      let(:value) { 'ls' }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include /should be an array of strings/
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
