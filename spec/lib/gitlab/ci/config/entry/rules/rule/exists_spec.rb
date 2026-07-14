# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Rules::Rule::Exists, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .metadata(metadata)
      .value(config)
  end

  let(:metadata) { {} }

  subject(:entry) { factory.create! }

  before do
    entry.compose!
  end

  shared_examples 'a valid config' do |expected_value = nil|
    it { is_expected.to be_valid }

    it 'returns the expected value' do
      expect(entry.value).to eq(expected_value || config.compact)
    end
  end

  context 'with a string' do
    let(:config) { 'abc.txt' }

    it_behaves_like 'a valid config', { paths: ['abc.txt'] }
  end

  context 'with a nil value' do
    let(:config) { nil }

    it 'returns the expected value' do
      is_expected.to be_valid
      expect(entry.value).to be_nil
    end
  end

  context 'with an array' do
    context 'when string array' do
      let(:config) { ['this.md', 'subdir/that.md'] }

      it_behaves_like 'a valid config', { paths: ['this.md', 'subdir/that.md'] }
    end

    context 'when empty array' do
      let(:config) { [] }

      it_behaves_like 'a valid config', { paths: [] }
    end

    context 'when integer array' do
      let(:config) { [1, 2] }

      it 'returns an error' do
        is_expected.not_to be_valid
        expect(entry.errors).to include(/should be an array of strings/)
      end
    end

    context 'when long array' do
      let(:config) { ['**/test.md'] * 51 }

      it 'returns an error' do
        is_expected.not_to be_valid
        expect(entry.errors).to include(/has too many entries \(maximum 50\)/)
      end

      context 'when opt(:disable_simple_exists_paths_limit) is true' do
        let(:metadata) { { disable_simple_exists_paths_limit: true } }

        it_behaves_like 'a valid config', { paths: ['**/test.md'] * 51 }
      end
    end
  end

  context 'with a hash' do
    context 'when empty hash' do
      let(:config) { { paths: nil } }

      it_behaves_like 'a valid config', { paths: [] }
    end

    context 'when paths: is provided' do
      context 'with a nil value' do
        let(:config) { { paths: nil } }

        it_behaves_like 'a valid config', { paths: [] }
      end

      context 'with a string' do
        let(:config) { { paths: 'string' } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be an array of strings/)
        end
      end

      context 'with an array' do
        context 'when string array' do
          let(:config) { { paths: ['this.md', 'subdir/that.md'] } }

          it_behaves_like 'a valid config'
        end

        context 'when empty array' do
          let(:config) { { paths: [] } }

          it_behaves_like 'a valid config'
        end

        context 'when integer array' do
          let(:config) { { paths: [1, 2] } }

          it 'returns an error' do
            is_expected.not_to be_valid
            expect(entry.errors).to include(/should be an array of strings/)
          end
        end

        context 'when long array' do
          let(:config) { { paths: ['**/test.txt'] * 51 } }

          it 'returns an error' do
            is_expected.not_to be_valid
            expect(entry.errors).to include(/has too many entries \(maximum 50\)/)
          end
        end
      end
    end

    context 'when project: is provided' do
      let(:config) { { paths: ['abc.md'], project: 'path/to/project' } }

      it_behaves_like 'a valid config'

      context 'with a nil value' do
        let(:config) { { paths: ['abc.md'], project: nil } }

        it_behaves_like 'a valid config'
      end

      context 'with an array' do
        let(:config) { { paths: ['abc.md'], project: ['path/to/project'] } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end

      context 'without paths:' do
        let(:config) { { project: ['path/to/project'] } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end
    end

    context 'when ref: is provided' do
      let(:config) { { paths: ['abc.md'], project: 'path/to/project', ref: 'ref' } }

      it_behaves_like 'a valid config'

      context 'with a nil value' do
        let(:config) { { paths: ['abc.md'], project: 'path/to/project', ref: nil } }

        it_behaves_like 'a valid config'
      end

      context 'with an array' do
        let(:config) { { paths: ['abc.md'], project: 'path/to/project', ref: ['ref'] } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end

      context 'without paths:' do
        let(:config) { { project: 'path/to/project', ref: ['ref'] } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end

      context 'without project:' do
        let(:config) { { paths: ['abc.md'], ref: ['ref'] } }

        it 'returns an error' do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end
    end

    context 'with an invalid keyword' do
      let(:config) { { paths: ['abc.md'], invalid: 'invalid' } }

      it 'returns an error' do
        is_expected.not_to be_valid
        expect(entry.errors).to include(/contains unknown keys: invalid/)
      end
    end

    context 'with regexp:' do
      context 'when regexp is a valid pattern' do
        let(:config) { { regexp: '^src/.*\.rb$' } }

        it_behaves_like 'a valid config'
      end

      context 'when regexp uses a negative lookahead for negation' do
        let(:config) { { regexp: '^(?!docs/)' } }

        it_behaves_like 'a valid config'
      end

      context 'when regexp uses alternation for negation' do
        let(:config) { { regexp: '^(?:src|lib|spec)/' } }

        it_behaves_like 'a valid config'
      end

      context 'when regexp is an invalid pattern' do
        let(:config) { { regexp: '[invalid' } }

        it 'returns an error', :aggregate_failures do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/regexp is invalid/)
        end
      end

      context 'when regexp exceeds the maximum length' do
        let(:config) { { regexp: 'a' * 256 } }

        it 'returns an error', :aggregate_failures do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/regexp is too long/)
        end
      end

      context 'when regexp is not a string' do
        let(:config) { { regexp: 123 } }

        it 'returns an error', :aggregate_failures do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/should be a string/)
        end
      end

      context 'when both paths and regexp are provided' do
        let(:config) { { paths: ['abc.md'], regexp: '^src/.*' } }

        it 'returns an error', :aggregate_failures do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/must use exactly one of these keys: paths, regexp/)
        end
      end

      context 'when neither paths nor regexp is provided' do
        let(:config) { { project: 'path/to/project' } }

        it 'returns an error', :aggregate_failures do
          is_expected.not_to be_valid
          expect(entry.errors).to include(/must use exactly one of these keys: paths, regexp/)
        end
      end

      context 'when regexp is used with project:' do
        let(:config) { { regexp: '^src/.*', project: 'path/to/project' } }

        it_behaves_like 'a valid config'
      end
    end
  end

  context 'when the policy strategy does not match' do
    let(:config) { 123 }

    it 'returns an error' do
      is_expected.not_to be_valid
      expect(entry.errors).to include(/should be a string, an array of strings, or a hash/)
    end
  end
end
