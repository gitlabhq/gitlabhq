# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Spamcheck::Result, feature_category: :instance_resiliency do
  include_context 'includes Spam constants'

  describe "#initialize", :aggregate_failures do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(response) }

    where(:verdict_value, :expected, :verdict_evaluated, :verdict_score) do
      ::Spamcheck::SpamVerdict::Verdict::ALLOW              | Spam::SpamConstants::ALLOW              | true  | 0.01
      ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW  | Spam::SpamConstants::CONDITIONAL_ALLOW  | true  | 0.50
      ::Spamcheck::SpamVerdict::Verdict::DISALLOW           | Spam::SpamConstants::DISALLOW           | true  | 0.75
      ::Spamcheck::SpamVerdict::Verdict::BLOCK              | Spam::SpamConstants::BLOCK_USER         | true  | 0.99
      ::Spamcheck::SpamVerdict::Verdict::NOOP               | Spam::SpamConstants::NOOP               | false | 0.0
    end

    with_them do
      let(:response) do
        verdict = ::Spamcheck::SpamVerdict.new
        verdict.verdict = verdict_value
        verdict.evaluated = verdict_evaluated
        verdict.score = verdict_score
        verdict
      end

      it "returns expected verdict" do
        expect(subject.verdict).to eq(expected)
      end

      it "returns expected evaluated?" do
        expect(subject.evaluated?).to eq(verdict_evaluated)
      end

      it "returns expected score" do
        expect(subject.score).to be_within(0.000001).of(verdict_score)
      end
    end
  end
end
