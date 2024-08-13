# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::Parser, feature_category: :continuous_integration do
  let(:parser) { described_class.new(input) }

  subject { parser.parse }

  context 'with an empty array' do
    let(:input) { [] }

    it { is_expected.to be_empty }
  end

  context 'with regular data' do
    let(:input) { 'cool, data, I,have' }

    it { is_expected.to match_array(%w[cool data I have]) }
  end

  context 'with multiple quoted tags' do
    let(:input) { '"Ruby Monsters","eat Katzenzungen"' }

    it { is_expected.to match_array(['Ruby Monsters', 'eat Katzenzungen']) }
  end

  context 'with single quotes' do
    let(:input) { "'I have', cool, data" }

    it { is_expected.to match_array(['I have', 'cool', 'data']) }
  end

  context 'with double quotes' do
    let(:input) { '"I have",cool, data' }

    it { is_expected.to match_array(['I have', 'cool', 'data']) }
  end
end
