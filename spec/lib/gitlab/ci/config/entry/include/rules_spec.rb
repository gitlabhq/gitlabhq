# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Include::Rules do
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

        it_behaves_like 'an invalid config', /contains unknown keys: changes/
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

    context 'with an "if"' do
      let(:config) do
        [{ if: '$THIS == "that"' }]
      end

      it { is_expected.to eq(config) }
    end

    context 'with a list of two rules' do
      let(:config) do
        [
          { if: '$THIS == "that"' },
          { if: '$SKIP' }
        ]
      end

      it { is_expected.to eq(config) }
    end
  end
end
