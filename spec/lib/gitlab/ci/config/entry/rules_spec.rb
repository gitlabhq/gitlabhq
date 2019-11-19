# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/helpers/stub_feature_flags'
require_dependency 'active_model'

describe Gitlab::Ci::Config::Entry::Rules do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .metadata(metadata)
      .value(config)
  end

  let(:metadata) { { allowed_when: %w[always never] } }
  let(:entry)    { factory.create! }

  describe '.new' do
    subject { entry }

    context 'with a list of rule rule' do
      let(:config) do
        [{ if: '$THIS == "that"', when: 'never' }]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }

      context 'when composed' do
        before do
          subject.compose!
        end

        it { is_expected.to be_valid }
      end
    end

    context 'with a list of two rules' do
      let(:config) do
        [
          { if: '$THIS == "that"', when: 'always' },
          { if: '$SKIP',           when: 'never' }
        ]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }

      context 'when composed' do
        before do
          subject.compose!
        end

        it { is_expected.to be_valid }
      end
    end

    context 'with a single rule object' do
      let(:config) do
        { if: '$SKIP', when: 'never' }
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe '#value' do
    subject { entry.value }

    context 'with a list of rule rule' do
      let(:config) do
        [{ if: '$THIS == "that"', when: 'never' }]
      end

      it { is_expected.to eq(config) }
    end

    context 'with a list of two rules' do
      let(:config) do
        [
          { if: '$THIS == "that"', when: 'always' },
          { if: '$SKIP',           when: 'never' }
        ]
      end

      it { is_expected.to eq(config) }
    end

    context 'with a single rule object' do
      let(:config) do
        { if: '$SKIP', when: 'never' }
      end

      it { is_expected.to eq(config) }
    end
  end

  describe '.default' do
    it 'does not have default policy' do
      expect(described_class.default).to be_nil
    end
  end
end
