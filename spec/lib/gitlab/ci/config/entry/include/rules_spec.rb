# frozen_string_literal: true

# require 'fast_spec_helper' -- this no longer runs under fast_spec_helper
require 'spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Include::Rules, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(config)
  end

  subject(:entry) { factory.create! }

  describe '.new' do
    shared_examples 'a valid config' do
      it { is_expected.to be_valid }

      context 'when composed' do
        before do
          entry.compose!
        end

        it { is_expected.to be_valid }
      end
    end

    shared_examples 'an invalid config' do |error_message|
      it { is_expected.not_to be_valid }

      it 'has errors' do
        expect(entry.errors).to include(error_message)
      end
    end

    context 'with an "if"' do
      let(:config) do
        [{ if: '$THIS == "that"' }]
      end

      it_behaves_like 'a valid config'
    end

    context 'with a "changes"' do
      let(:config) do
        [{ changes: ['filename.txt'] }]
      end

      context 'when composed' do
        before do
          entry.compose!
        end

        it_behaves_like 'a valid config'
      end
    end

    context 'with a list of two rules' do
      let(:config) do
        [
          { if: '$THIS == "that"' },
          { if: '$SKIP' }
        ]
      end

      it_behaves_like 'a valid config'
    end

    context 'without an array' do
      let(:config) do
        { if: '$SKIP' }
      end

      it_behaves_like 'an invalid config', /should be a array/
    end
  end

  describe '#value' do
    subject(:value) { entry.value }

    let(:config) do
      [
        { if: '$THIS == "that"' },
        { if: '$SKIP', when: 'never' },
        { changes: ['Dockerfile'] }
      ]
    end

    it { is_expected.to eq([]) }

    context 'when composed' do
      before do
        entry.compose!
      end

      it 'returns the composed entries value' do
        expect(entry).to be_valid
        is_expected.to eq(
          [
            { if: '$THIS == "that"' },
            { if: '$SKIP', when: 'never' },
            { changes: { paths: ['Dockerfile'] } }
          ]
        )
      end

      context 'when invalid' do
        let(:config) do
          [
            { if: '$THIS == "that"' },
            { if: '$SKIP', invalid: 'invalid' }
          ]
        end

        it 'returns the invalid config' do
          expect(entry).not_to be_valid
          is_expected.to eq(config)
        end
      end
    end
  end
end
