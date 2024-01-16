# frozen_string_literal: true

require 'spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Rules, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .metadata(metadata)
      .value(config)
  end

  let(:metadata) do
    { allowed_when: %w[always never], allowed_keys: %i[if when] }
  end

  subject(:entry) { factory.create! }

  describe '.new' do
    before do
      entry.compose!
    end

    context 'with a list of rule rule' do
      let(:config) do
        [{ if: '$THIS == "that"', when: 'never' }]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }
    end

    context 'with a list of two rules' do
      let(:config) do
        [
          { if: '$THIS == "that"', when: 'always' },
          { if: '$SKIP',           when: 'never' }
        ]
      end

      it { is_expected.to be_valid }
    end

    context 'with a single rule object' do
      let(:config) do
        { if: '$SKIP', when: 'never' }
      end

      it { is_expected.not_to be_valid }
    end

    context 'with nested rules' do
      let(:config) do
        [
          { if: '$THIS == "that"', when: 'always' },
          [{ if: '$SKIP', when: 'never' }, { if: '$THIS == "other"', when: 'always' }]
        ]
      end

      it { is_expected.to be_valid }
    end

    context 'with rules nested more than one level' do
      let(:config) do
        [
          { if: '$THIS == "that"', when: 'always' },
          [{ if: '$SKIP', when: 'never' }, [{ if: '$THIS == "other"', when: 'always' }]]
        ]
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#value' do
    subject(:value) { entry.value }

    before do
      entry.compose!
    end

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

      it { is_expected.to eq([]) }
    end

    context 'with nested rules' do
      let(:first_rule) { { if: '$THIS == "that"', when: 'always' } }
      let(:second_rule) { { if: '$SKIP', when: 'never' } }

      let(:config) do
        [
          first_rule,
          [second_rule]
        ]
      end

      it { is_expected.to contain_exactly(first_rule, second_rule) }
    end

    context 'with rules nested more than one level' do
      let(:first_rule) { { if: '$THIS == "that"', when: 'always' } }
      let(:second_rule) { { if: '$SKIP', when: 'never' } }
      let(:third_rule) { { if: '$THIS == "other"', when: 'always' } }

      let(:config) do
        [
          first_rule,
          [second_rule, [third_rule]]
        ]
      end

      it { is_expected.to contain_exactly(first_rule, second_rule, third_rule) }
    end
  end

  describe '.default' do
    it 'does not have default policy' do
      expect(described_class.default).to be_nil
    end
  end
end
