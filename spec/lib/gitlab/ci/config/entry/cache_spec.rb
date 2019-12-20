# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Cache do
  subject(:entry) { described_class.new(config) }

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:policy) { nil }
      let(:key) { 'some key' }

      let(:config) do
        { key: key,
          untracked: true,
          paths: ['some/path/'],
          policy: policy }
      end

      describe '#value' do
        shared_examples 'hash key value' do
          it 'returns hash value' do
            expect(entry.value).to eq(key: key, untracked: true, paths: ['some/path/'], policy: 'pull-push')
          end
        end

        it_behaves_like 'hash key value'

        context 'with files' do
          let(:key) { { files: %w[a-file other-file] } }

          it_behaves_like 'hash key value'
        end

        context 'with files and prefix' do
          let(:key) { { files: %w[a-file other-file], prefix: 'prefix-value' } }

          it_behaves_like 'hash key value'
        end

        context 'with prefix' do
          let(:key) { { prefix: 'prefix-value' } }

          it 'key is nil' do
            expect(entry.value).to match(a_hash_including(key: nil))
          end
        end
      end

      describe '#valid?' do
        it { is_expected.to be_valid }

        context 'with files' do
          let(:key) { { files: %w[a-file other-file] } }

          it { is_expected.to be_valid }
        end
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
          context 'with invalid keys' do
            let(:config) { { key: 1 } }

            it 'reports error with descendants' do
              is_expected.to include 'key should be a hash, a string or a symbol'
            end
          end

          context 'with empty key' do
            let(:config) { { key: {} } }

            it 'reports error with descendants' do
              is_expected.to include 'key config missing required keys: files'
            end
          end

          context 'with invalid files' do
            let(:config) { { key: { files: 'a-file' } } }

            it 'reports error with descendants' do
              is_expected.to include 'key:files config should be an array of strings'
            end
          end

          context 'with prefix without files' do
            let(:config) { { key: { prefix: 'a-prefix' } } }

            it 'reports error with descendants' do
              is_expected.to include 'key config missing required keys: files'
            end
          end

          context 'when there is an unknown key present' do
            let(:config) { { key: { unknown: 'a-file' } } }

            it 'reports error with descendants' do
              is_expected.to include 'key config contains unknown keys: unknown'
            end
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
