# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Cache do
  using RSpec::Parameterized::TableSyntax

  subject(:entry) { described_class.new(config) }

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:policy) { nil }
      let(:key) { 'some key' }
      let(:when_config) { nil }
      let(:unprotect) { false }
      let(:fallback_keys) { [] }

      let(:config) do
        {
          key: key,
          untracked: true,
          paths: ['some/path/'],
          unprotect: unprotect
        }.tap do |config|
          config[:policy] = policy if policy
          config[:when] = when_config if when_config
          config[:fallback_keys] = fallback_keys if fallback_keys
        end
      end

      describe '#value' do
        shared_examples 'hash key value' do
          it 'returns hash value' do
            expect(entry.value).to eq(
              key: key,
              untracked: true,
              paths: ['some/path/'],
              policy: 'pull-push',
              when: 'on_success',
              unprotect: false,
              fallback_keys: []
            )
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

        context 'with option `unprotect` specified' do
          let(:unprotect) { true }

          it 'returns true' do
            expect(entry.value).to match(a_hash_including(unprotect: true))
          end
        end

        context 'with `policy`' do
          where(:policy, :result) do
            'pull-push' | 'pull-push'
            'push'      | 'push'
            'pull'      | 'pull'
            '$VARIABLE' | '$VARIABLE'
            'unknown'   | 'unknown' # invalid
          end

          with_them do
            it { expect(entry.value).to include(policy: result) }
          end
        end

        context 'without `policy`' do
          it 'assigns policy to default' do
            expect(entry.value).to include(policy: 'pull-push')
          end
        end

        context 'with `when`' do
          where(:when_config, :result) do
            'on_success' | 'on_success'
            'on_failure' | 'on_failure'
            'always'     | 'always'
            'unknown'    | 'unknown' # invalid
          end

          with_them do
            it { expect(entry.value).to include(when: result) }
          end
        end

        context 'without `when`' do
          it 'assigns when to default' do
            expect(entry.value).to include(when: 'on_success')
          end
        end

        context 'with `fallback_keys`' do
          let(:fallback_keys) { %w[key-1 key-2] }

          it 'matches the list of fallback keys' do
            expect(entry.value).to match(a_hash_including(fallback_keys: %w[key-1 key-2]))
          end
        end

        context 'without `fallback_keys`' do
          it 'assigns an empty list' do
            expect(entry.value).to match(a_hash_including(fallback_keys: []))
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

      context 'with `policy`' do
        where(:policy, :valid) do
          'pull-push' | true
          'push'      | true
          'pull'      | true
          '$VARIABLE' | true
          'unknown'   | false
        end

        with_them do
          it 'returns expected validity' do
            expect(entry.valid?).to eq(valid)
          end
        end
      end

      context 'with `when`' do
        where(:when_config, :valid) do
          'on_success' | true
          'on_failure' | true
          'always'     | true
          'unknown'    | false
        end

        with_them do
          it 'returns expected validity' do
            expect(entry.valid?).to eq(valid)
          end
        end
      end

      context 'with key missing' do
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

        context 'when the `when` keyword is not a valid string' do
          context 'when `when` is unknown' do
            let(:config) { { when: 'unknown' } }

            it 'returns error' do
              is_expected.to include('cache when should be one of: on_success, on_failure, always')
            end
          end

          context 'when it is an array' do
            let(:config) { { when: ['always'] } }

            it 'returns error' do
              expect(entry).not_to be_valid
              is_expected.to include('cache when should be a string')
            end
          end

          context 'when it is a boolean' do
            let(:config) { { when: true } }

            it 'returns error' do
              expect(entry).not_to be_valid
              is_expected.to include('cache when should be a string')
            end
          end
        end

        context 'when the `policy` keyword is not a valid string' do
          context 'when `policy` is unknown' do
            let(:config) { { policy: 'unknown' } }

            it 'returns error' do
              is_expected.to include('cache policy should be a variable or one of: pull-push, push, pull')
            end
          end

          context 'when it is an array' do
            let(:config) { { policy: ['pull-push'] } }

            it 'returns error' do
              expect(entry).not_to be_valid
              is_expected.to include('cache policy should be a string')
            end
          end

          context 'when it is a boolean' do
            let(:config) { { policy: true } }

            it 'returns error' do
              expect(entry).not_to be_valid
              is_expected.to include('cache policy should be a string')
            end
          end
        end
      end
    end
  end
end
