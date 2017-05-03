require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Cache do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    before { entry.compose! }

    context 'when entry config value is correct' do
      let(:config) do
        { key: 'some key',
          untracked: true,
          paths: ['some/path/'] }
      end

      describe '#value' do
        it 'returns hash value' do
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
      describe '#errors' do
        context 'when is not a hash' do
          let(:config) { 'ls' }

          it 'reports errors with config value' do
            expect(entry.errors)
              .to include 'cache config should be a hash'
          end
        end

        context 'when descendants are invalid' do
          let(:config) { { key: 1 } }

          it 'reports error with descendants' do
            expect(entry.errors)
              .to include 'key config should be a string or symbol'
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { invalid: true } }

          it 'reports error with descendants' do
            expect(entry.errors)
              .to include 'cache config contains unknown keys: invalid'
          end
        end
      end
    end
  end
end
