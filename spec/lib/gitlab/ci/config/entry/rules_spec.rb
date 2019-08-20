require 'fast_spec_helper'
require 'support/helpers/stub_feature_flags'
require_dependency 'active_model'

describe Gitlab::Ci::Config::Entry::Rules do
  let(:entry) { described_class.new(config) }

  describe '.new' do
    subject { entry }

    context 'with a list of rule rule' do
      let(:config) do
        [{ if: '$THIS == "that"', when: 'never' }]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }

      context 'after #compose!' do
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

      context 'after #compose!' do
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

    context 'with an invalid boolean when:' do
      let(:config) do
        [{ if: '$THIS == "that"', when: false }]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }

      context 'after #compose!' do
        before do
          subject.compose!
        end

        it { is_expected.not_to be_valid }

        it 'returns an error about invalid when:' do
          expect(subject.errors).to include(/when unknown value: false/)
        end
      end
    end

    context 'with an invalid string when:' do
      let(:config) do
        [{ if: '$THIS == "that"', when: 'explode' }]
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to be_valid }

      context 'after #compose!' do
        before do
          subject.compose!
        end

        it { is_expected.not_to be_valid }

        it 'returns an error about invalid when:' do
          expect(subject.errors).to include(/when unknown value: explode/)
        end
      end
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
