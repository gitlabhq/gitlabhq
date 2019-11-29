# frozen_string_literal: true

require 'spec_helper'

describe ConversationalDevelopmentIndex::MetricPresenter do
  subject { described_class.new(metric) }

  let(:metric) { build(:dev_ops_score_metric) }

  describe '#cards' do
    it 'includes instance score, leader score and percentage score' do
      issues_card = subject.cards.first

      expect(issues_card.instance_score).to eq(1.234)
      expect(issues_card.leader_score).to eq(9.256)
      expect(issues_card.percentage_score).to eq(13.331)
    end
  end

  describe '#idea_to_production_steps' do
    it 'returns percentage score when it depends on a single feature' do
      code_step = subject.idea_to_production_steps.fourth

      expect(code_step.percentage_score).to be_within(0.1).of(50.0)
    end

    it 'returns percentage score when it depends on two features' do
      issue_step = subject.idea_to_production_steps.second

      expect(issue_step.percentage_score).to be_within(0.1).of(53.0)
    end
  end

  describe '#average_percentage_score' do
    it 'calculates an average value across all the features' do
      expect(subject.average_percentage_score).to be_within(0.1).of(55.8)
    end
  end
end
