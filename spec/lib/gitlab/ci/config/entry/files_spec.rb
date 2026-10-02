# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Files, feature_category: :pipeline_composition do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is valid' do
      let(:config) { ['some/file', 'some/path/'] }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry config contains absolute paths' do
      let(:config) { ['/absolute/path', 'relative/path'] }

      describe '#value' do
        it 'strips leading slashes from absolute paths' do
          expect(entry.value).to match_array ['absolute/path', 'relative/path']
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry config contains only absolute paths' do
      let(:config) { ['/tmp/test.txt', '/var/log/app.log'] }

      describe '#value' do
        it 'strips leading slashes from all paths' do
          expect(entry.value).to match_array ['tmp/test.txt', 'var/log/app.log']
        end
      end
    end

    context 'when entry config contains paths with multiple leading slashes' do
      let(:config) { ['//double/slash', '///triple/slash'] }

      describe '#value' do
        it 'strips all leading slashes' do
          expect(entry.value).to match_array ['double/slash', 'triple/slash']
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry config contains empty strings' do
      let(:config) { ['', 'valid/path'] }

      describe '#value' do
        it 'preserves empty strings' do
          expect(entry.value).to match_array ['', 'valid/path']
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    describe '#errors' do
      context 'when entry value is not an array' do
        let(:config) { 'string' }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config should be an array of strings'
        end
      end

      context 'when entry value is not an array of strings' do
        let(:config) { [1] }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config should be an array of strings'
        end
      end

      context 'when entry value is an empty array' do
        let(:config) { [] }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config requires at least 1 item'
        end
      end

      context 'when entry value contains more than two values' do
        let(:config) { %w[file1 file2 file3] }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config has too many items (maximum is 2)'
        end
      end

      context 'when a maximum is given' do
        let(:entry) do
          Gitlab::Ci::Config::FeatureFlags.with_actor(nil) { described_class.new(config, max_size: 3) }
        end

        context 'when entry value is within the maximum' do
          let(:config) { %w[file1 file2 file3] }

          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        context 'when entry value exceeds the maximum' do
          let(:config) { %w[file1 file2 file3 file4] }

          it 'saves errors' do
            expect(entry.errors)
              .to include 'files config has too many items (maximum is 3)'
          end
        end

        context 'when the increase_ci_cache_key_files_limit feature flag is disabled' do
          let(:config) { %w[file1 file2 file3] }

          before do
            stub_feature_flags(increase_ci_cache_key_files_limit: false)
          end

          it 'uses the default maximum' do
            expect(entry.errors)
              .to include 'files config has too many items (maximum is 2)'
          end
        end
      end
    end
  end
end
