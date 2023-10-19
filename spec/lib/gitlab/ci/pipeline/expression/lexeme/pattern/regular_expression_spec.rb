# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::Pattern::RegularExpression, feature_category: :continuous_integration do
  describe '#initialize' do
    it 'initializes the pattern' do
      pattern = described_class.new('/foo/')

      expect(pattern.value).to eq('/foo/')
    end
  end

  describe '#valid?' do
    subject { described_class.new(pattern).valid? }

    context 'with valid expressions' do
      let(:pattern) { '/foo\\/bar/' }

      it { is_expected.to be_truthy }
    end

    context 'when the value is not a valid regular expression' do
      let(:pattern) { 'foo' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#expression' do
    subject { described_class.new(pattern).expression }

    context 'with valid expressions' do
      let(:pattern) { '/bar/' }

      it { is_expected.to eq Gitlab::UntrustedRegexp.new('bar') }
    end

    context 'when the value is not a valid regular expression' do
      let(:pattern) { 'foo' }

      it { expect { subject }.to raise_error(RegexpError) }
    end

    context 'when the request store is activated', :request_store do
      let(:pattern) { '/foo\\/bar/' }

      it 'fabricates once' do
        expect(Gitlab::UntrustedRegexp::RubySyntax).to receive(:fabricate!).once.and_call_original

        2.times do
          expect(described_class.new(pattern).expression).to be_a(Gitlab::UntrustedRegexp)
        end
      end
    end
  end
end
