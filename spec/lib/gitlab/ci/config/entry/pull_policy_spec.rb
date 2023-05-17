# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::PullPolicy, feature_category: :continuous_integration do
  let(:entry) { described_class.new(config) }

  describe '#value' do
    subject(:value) { entry.value }

    context 'when config value is nil' do
      let(:config) { nil }

      it { is_expected.to be_nil }
    end

    context 'when retry value is an empty array' do
      let(:config) { [] }

      it { is_expected.to eq(nil) }
    end

    context 'when retry value is string' do
      let(:config) { "always" }

      it { is_expected.to eq(%w[always]) }
    end

    context 'when retry value is array' do
      let(:config) { %w[always if-not-present] }

      it { is_expected.to eq(%w[always if-not-present]) }
    end
  end

  describe 'validation' do
    subject(:valid?) { entry.valid? }

    context 'when retry value is nil' do
      let(:config) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when retry value is an empty array' do
      let(:config) { [] }

      it { is_expected.to eq(false) }
    end

    context 'when retry value is a hash' do
      let(:config) { {} }

      it { is_expected.to eq(false) }
    end

    context 'when retry value is string' do
      let(:config) { "always" }

      it { is_expected.to eq(true) }

      context 'when it is an invalid policy' do
        let(:config) { "invalid" }

        it { is_expected.to eq(false) }
      end

      context 'when it is an empty string' do
        let(:config) { "" }

        it { is_expected.to eq(false) }
      end
    end

    context 'when retry value is array' do
      let(:config) { %w[always if-not-present] }

      it { is_expected.to eq(true) }

      context 'when config contains an invalid policy' do
        let(:config) { %w[always invalid] }

        it { is_expected.to eq(false) }
      end
    end
  end
end
