# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input::Rules::Rule, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(config)
  end

  subject(:entry) { factory.create! }

  describe 'validations' do
    context 'with if and options' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b] } }

      it { is_expected.not_to be_valid }

      it 'has error about missing default' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value and a 'default'/)
      end
    end

    context 'with if and default (no options)' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', default: 'value' } }

      it { is_expected.to be_valid }
    end

    context 'with if, options, and default' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b], default: 'a' } }

      it { is_expected.to be_valid }
    end

    context 'with fallback rule having both options and default' do
      let(:config) { { options: %w[a b], default: 'a' } }

      it { is_expected.to be_valid }
    end

    context "when rule has 'if' but no 'options' or 'default'" do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"' } }

      it { is_expected.not_to be_valid }

      it 'has error about missing options and default' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value and a 'default'/)
      end
    end

    context 'when if is not a valid expression' do
      let(:config) { { if: 123, options: %w[a b] } }

      it { is_expected.not_to be_valid }

      it 'has error about invalid expression' do
        entry.compose!
        expect(entry.errors).to include(/invalid expression syntax/i)
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

    context 'when default is not in options list' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: %w[a b], default: 'c' } }

      it { is_expected.not_to be_valid }

      it 'has error about invalid default' do
        entry.compose!
        expect(entry.errors).to include(/default 'c' must be one of the options/)
      end
    end

    context 'when fallback rule default is not in options list' do
      let(:config) { { options: %w[a b], default: 'c' } }

      it { is_expected.not_to be_valid }

      it 'has error about invalid default' do
        entry.compose!
        expect(entry.errors).to include(/default 'c' must be one of the options/)
      end
    end

    context 'when rule with if has empty options and no default' do
      let(:config) { { if: '$[[ inputs.env ]] == "prod"', options: [] } }

      it { is_expected.not_to be_valid }

      it 'has error about missing options and default' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value and a 'default'/)
      end
    end

    context 'when fallback rule has empty options' do
      let(:config) { { options: [] } }

      it { is_expected.not_to be_valid }

      it 'has error about missing options' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value/)
      end
    end

    context 'when fallback rule has empty string options but no default' do
      let(:config) { { options: [''] } }

      it { is_expected.not_to be_valid }

      it 'has error about missing default' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value and a 'default'/)
      end
    end

    context 'when fallback rule has empty string options with default' do
      let(:config) { { options: [''], default: '' } }

      it { is_expected.to be_valid }
    end

    context 'when fallback rule has options but no default' do
      let(:config) { { options: %w[a b] } }

      it { is_expected.not_to be_valid }

      it 'has error about missing default' do
        entry.compose!
        expect(entry.errors).to include(/must define 'options' with at least one value and a 'default'/)
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
