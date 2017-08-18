require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Cache do
  subject(:entry) { described_class.new(config) }

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:policy) { nil }

      let(:config) do
        { key: 'some key',
          untracked: true,
          paths: ['some/path/'],
          policy: policy }
      end

      describe '#value' do
        it 'returns hash value' do
          expect(entry.value).to eq(key: 'some key', untracked: true, paths: ['some/path/'], policy: 'pull-push')
        end
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      context 'policy is pull-push' do
        let(:policy) { 'pull-push' }

        it { is_expected.to be_valid }
        it { expect(entry.value).to include(policy: 'pull-push') }
      end

      context 'policy is push' do
        let(:policy) { 'push' }

        it { is_expected.to be_valid }
        it { expect(entry.value).to include(policy: 'push') }
      end

      context 'policy is pull' do
        let(:policy) { 'pull' }

        it { is_expected.to be_valid }
        it { expect(entry.value).to include(policy: 'pull') }
      end

      context 'when key is missing' do
        let(:config) do
          { untracked: true,
            paths: ['some/path/'] }
        end

        describe '#value' do
          it 'sets key with the default' do
            expect(entry.value[:key])
              .to eq(Gitlab::Ci::Config::Entry::Key.default)
          end
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        subject { entry.errors }
        context 'when is not a hash' do
          let(:config) { 'ls' }

          it 'reports errors with config value' do
            is_expected.to include 'cache config should be a hash'
          end
        end

        context 'when policy is unknown' do
          let(:config) { { policy: "unknown" } }

          it 'reports error' do
            is_expected.to include('cache policy should be pull-push, push, or pull')
          end
        end

        context 'when descendants are invalid' do
          let(:config) { { key: 1 } }

          it 'reports error with descendants' do
            is_expected.to include 'key config should be a string or symbol'
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { invalid: true } }

          it 'reports error with descendants' do
            is_expected.to include 'cache config contains unknown keys: invalid'
          end
        end
      end
    end
  end
end
