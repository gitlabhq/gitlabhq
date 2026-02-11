# frozen_string_literal: true

# Shared examples for include entry classes that use BaseInclude concern
# Used by:
# - spec/lib/gitlab/ci/config/entry/include_spec.rb
# - spec/lib/gitlab/ci/config/header/include_spec.rb

RSpec.shared_examples 'basic include validations' do
  describe 'validations' do
    before do
      include_entry.compose!
    end

    context 'when value is a string' do
      let(:config) { 'test.yml' }

      it { is_expected.to be_valid }
    end

    context 'when value is hash with common keywords' do
      context 'when using "local"' do
        let(:config) { { local: 'test.yml' } }

        it { is_expected.to be_valid }

        context 'with array of values' do
          let(:config) { { local: ['file1.yml', 'file2.yml'] } }

          it { is_expected.to be_valid }
        end
      end

      context 'when using "file"' do
        let(:config) { { file: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "remote"' do
        let(:config) { { remote: 'https://example.com/file.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "project"' do
        context 'and specifying "file"' do
          let(:config) { { project: 'my-group/my-project', file: 'test.yml' } }

          it { is_expected.to be_valid }
        end

        context 'without "file"' do
          let(:config) { { project: 'my-group/my-project' } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config must specify the file where to fetch the config from')
          end
        end
      end

      context 'when using unknown keywords' do
        let(:config) { { unknown: 'value' } }

        it { is_expected.not_to be_valid }
      end
    end

    context 'when value is something else' do
      let(:config) { 123 }

      it { is_expected.not_to be_valid }
    end
  end
end

RSpec.shared_examples 'cache validation for includes' do
  describe 'cache validation' do
    before do
      include_entry.compose!
    end

    context 'when using cache with non-remote include' do
      let(:config) { { local: 'file.yml', cache: true } }

      it { is_expected.not_to be_valid }

      it 'has specific error' do
        expect(include_entry.errors)
          .to include('include config cache can only be specified for remote includes')
      end
    end

    context 'when cache value is blank' do
      let(:config) { { remote: 'https://example.com/file.yml', cache: nil } }

      it { is_expected.to be_valid }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_cache_remote_includes: false)
      end

      context 'when using cache with boolean' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: true } }

        it { is_expected.to be_valid }
      end

      context 'when using cache with duration string' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: '1 day' } }

        it { is_expected.to be_valid }
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(ci_cache_remote_includes: true)
      end

      context 'when using cache with boolean true' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: true } }

        it { is_expected.to be_valid }
      end

      context 'when using cache with valid duration string' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: '1 day' } }

        it { is_expected.to be_valid }
      end

      context 'when using cache with duration at minimum bound' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: '1 minute' } }

        it { is_expected.to be_valid }
      end

      context 'when using cache with invalid type' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: 123 } }

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config cache must be a boolean or a duration string')
        end
      end

      context 'when using cache with invalid duration string' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: 'invalid' } }

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config cache contains an invalid duration')
        end
      end

      context 'when using cache with duration below minimum' do
        let(:config) { { remote: 'https://example.com/file.yml', cache: '30 seconds' } }

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config cache duration must be at least 1 minute')
        end
      end
    end
  end
end

RSpec.shared_examples 'integrity validation for includes' do
  describe 'integrity validation' do
    before do
      include_entry.compose!
    end

    context 'when using "remote" with integrity' do
      let(:config) do
        {
          remote: 'https://example.com/file.yml',
          integrity: 'sha256-abc123def456'
        }
      end

      it { is_expected.to be_valid }

      context 'when integrity has invalid format' do
        ['invalid-hash', 123].each do |invalid_integrity|
          context "when integrity is #{invalid_integrity}" do
            let(:config) do
              {
                remote: 'https://example.com/file.yml',
                integrity: invalid_integrity
              }
            end

            it { is_expected.not_to be_valid }

            it 'has specific error' do
              expect(include_entry.errors)
                .to include('include config integrity hash must start with \'sha256-\'')
            end
          end
        end
      end

      context 'when integrity is not base64 encoded' do
        let(:config) do
          {
            remote: 'https://example.com/file.yml',
            integrity: 'sha256-not!valid@base64'
          }
        end

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config integrity hash must be base64 encoded')
        end
      end

      context 'when integrity is used without remote' do
        let(:config) do
          {
            local: 'test.yml',
            integrity: 'sha256-abc123def456'
          }
        end

        it { is_expected.not_to be_valid }

        it 'has specific error' do
          expect(include_entry.errors)
            .to include('include config integrity can only be specified for remote includes')
        end
      end
    end
  end
end
