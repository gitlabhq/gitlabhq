# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Rules::Rule::Changes, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(config)
  end

  subject(:entry) { factory.create! }

  before do
    entry.compose!
  end

  describe '.new' do
    context 'when using a string array' do
      let(:config) { %w[app/ lib/ spec/ other/* paths/**/*.rb] }

      it { is_expected.to be_valid }
    end

    context 'when using an integer array' do
      let(:config) { [1, 2] }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(entry.errors).to include(/changes config should be an array of strings/)
      end
    end

    context 'when using a string' do
      let(:config) { 'a regular string' }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid policy' do
        expect(entry.errors).to include(/should be an array or a hash/)
      end
    end

    context 'when using a long array' do
      let(:config) { ['app/'] * 51 }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(entry.errors).to include(/has too many entries \(maximum 50\)/)
      end
    end

    context 'when clause is empty' do
      let(:config) { nil }

      it { is_expected.to be_valid }
    end

    context 'when policy strategy does not match' do
      let(:config) { 'string strategy' }

      it { is_expected.not_to be_valid }

      it 'returns information about errors' do
        expect(entry.errors)
          .to include(/should be an array or a hash/)
      end
    end

    context 'with paths' do
      context 'when paths is an array of strings' do
        let(:config) { { paths: %w[app/ lib/] } }

        it { is_expected.to be_valid }
      end

      context 'when paths is not an array' do
        let(:config) { { paths: 'string' } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors)
            .to include(/should be an array of strings/)
        end
      end

      context 'when paths is an array of integers' do
        let(:config) { { paths: [1, 2] } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors)
            .to include(/should be an array of strings/)
        end
      end

      context 'when paths is an array of long strings' do
        let(:config) { { paths: ['a'] * 51 } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors)
            .to include(/has too many entries \(maximum 50\)/)
        end
      end

      context 'when paths is nil' do
        let(:config) { { paths: nil } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors)
            .to include(/should be an array of strings/)
        end
      end
    end

    context 'with paths and compare_to' do
      let(:config) { { paths: %w[app/ lib/], compare_to: 'branch1' } }

      it { is_expected.to be_valid }

      context 'when compare_to is not a string' do
        let(:config) { { paths: %w[app/ lib/], compare_to: 1 } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors)
            .to include(/should be a string/)
        end
      end
    end

    context 'with regexp' do
      context 'when regexp is a valid pattern' do
        let(:config) { { regexp: '^src/.*' } }

        it { is_expected.to be_valid }
      end

      context 'when regexp uses a negative lookahead for negation' do
        let(:config) { { regexp: '^(?!docs/)' } }

        it { is_expected.to be_valid }
      end

      context 'when regexp uses alternation for negation' do
        let(:config) { { regexp: '^(?:src|lib|spec)/' } }

        it { is_expected.to be_valid }
      end

      context 'when regexp is an invalid pattern' do
        let(:config) { { regexp: '[invalid' } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/regexp is invalid/)
        end
      end

      context 'when regexp exceeds the maximum length' do
        let(:config) { { regexp: 'a' * 256 } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/regexp is too long/)
        end
      end

      context 'when regexp is not a string' do
        let(:config) { { regexp: 123 } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/should be a string/)
        end
      end

      context 'when both paths and regexp are provided' do
        let(:config) { { paths: %w[app/ lib/], regexp: '^docs/.*' } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/must use exactly one of these keys: paths, regexp/)
        end
      end

      context 'when neither paths nor regexp is provided' do
        let(:config) { { compare_to: 'main' } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/must use exactly one of these keys: paths, regexp/)
        end
      end
    end

    context 'with regexp and compare_to' do
      let(:config) { { regexp: '^src/.*', compare_to: 'branch1' } }

      it { is_expected.to be_valid }

      context 'when compare_to is not a string' do
        let(:config) { { regexp: '^src/.*', compare_to: 1 } }

        it { is_expected.not_to be_valid }

        it 'returns information about errors' do
          expect(entry.errors).to include(/should be a string/)
        end
      end
    end
  end

  describe '#value' do
    subject(:value) { entry.value }

    context 'when using a string array' do
      let(:config) { %w[app/ lib/ spec/ other/* paths/**/*.rb] }

      it { is_expected.to eq(paths: config) }
    end

    context 'with paths' do
      let(:config) do
        { paths: ['app/', 'lib/'] }
      end

      it { is_expected.to eq(config) }
    end

    context 'with paths and compare_to' do
      let(:config) do
        { paths: ['app/', 'lib/'], compare_to: 'branch1' }
      end

      it { is_expected.to eq(config) }
    end

    context 'with regexp' do
      let(:config) { { regexp: '^src/.*' } }

      it { is_expected.to eq(config) }
    end
  end
end
