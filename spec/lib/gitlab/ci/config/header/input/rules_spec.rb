# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input::Rules, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(config)
  end

  subject(:entry) { factory.create! }

  describe 'validations' do
    context 'with a single rule' do
      let(:config) { [{ if: '$[[ inputs.env ]] == "prod"', options: %w[a b] }] }

      it { is_expected.to be_valid }
    end

    context 'with multiple rules' do
      let(:config) do
        [
          { if: '$[[ inputs.env ]] == "prod"', options: %w[large xlarge] },
          { options: %w[small] }
        ]
      end

      it { is_expected.to be_valid }
    end

    context 'with empty array' do
      let(:config) { [] }

      it { is_expected.to be_valid }
    end

    context 'when config is not an array' do
      let(:config) { { if: 'condition' } }

      it { is_expected.not_to be_valid }

      it 'has error about type' do
        entry.compose!
        expect(entry.errors).to include(/config should be an array/)
      end
    end
  end
end
