# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input::Rules::Rule, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(config)
  end

  subject(:entry) { factory.create! }

  describe 'validations' do
    context 'with if and options' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b] } }

      it { is_expected.to be_valid }
    end

    context 'with if and default (no options)' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', default: 'value' } }

      it { is_expected.to be_valid }
    end

    context 'with if, options, and default' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b], default: 'a' } }

      it { is_expected.to be_valid }
    end

    context 'with fallback rule' do
      let(:config) { { options: %w[a b] } }

      it { is_expected.to be_valid }
    end

    context 'with fallback rule having both options and default' do
      let(:config) { { options: %w[a b], default: 'a' } }

      it { is_expected.to be_valid }
    end

    context "when rule has 'if' but no 'options' or 'default'" do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"' } }

      it { is_expected.not_to be_valid }
    end

    context 'when fallback rule has no options' do
      let(:config) { { default: 'value' } }

      it { is_expected.not_to be_valid }
    end

    context 'when if is not a string' do
      let(:config) { { if: 123, options: %w[a b] } }

      it { is_expected.not_to be_valid }

      it 'has error about if type' do
        entry.compose!
        expect(entry.errors).to include(/if should be a string/)
      end
    end

    context 'when options is not an array' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: 'not-array' } }

      it { is_expected.not_to be_valid }

      it 'has error about options type' do
        entry.compose!
        expect(entry.errors).to include(/options should be an array/)
      end
    end

    context 'when options exceed limit' do
      let(:config) { { options: (1..51).to_a.map(&:to_s) } }

      it { is_expected.not_to be_valid }

      it 'has error about limit' do
        entry.compose!
        expect(entry.errors).to include(/cannot define more than 50 options/)
      end
    end

    context 'when options with if exceed limit' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: (1..51).to_a.map(&:to_s) } }

      it { is_expected.not_to be_valid }

      it 'has error about limit' do
        entry.compose!
        expect(entry.errors).to include(/cannot define more than 50 options/)
      end
    end

    context 'with empty config' do
      let(:config) { {} }

      it { is_expected.not_to be_valid }

      it 'has error about presence' do
        entry.compose!
        expect(entry.errors).to include(/can't be blank/)
      end
    end
  end

  describe '#value' do
    let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b], default: 'a' } }

    it 'returns the config hash' do
      expect(entry.value).to eq(config)
    end
  end
end
