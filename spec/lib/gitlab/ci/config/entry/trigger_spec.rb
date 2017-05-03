require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Trigger do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is valid' do
      context 'when config is a branch or tag name' do
        let(:config) { %w[master feature/branch] }

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        describe '#value' do
          it 'returns key value' do
            expect(entry.value).to eq config
          end
        end
      end

      context 'when config is a regexp' do
        let(:config) { ['/^issue-.*$/'] }

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when config is a special keyword' do
        let(:config) { %w[tags triggers branches] }

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end
    end

    context 'when entry value is not valid' do
      let(:config) { [1] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'trigger config should be an array of strings or regexps'
        end
      end
    end
  end
end
