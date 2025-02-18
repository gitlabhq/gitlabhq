# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidateMetric, feature_category: :mlops do
  describe 'associations' do
    it { is_expected.to belong_to(:candidate) }
  end

  describe 'scope :latest' do
    let_it_be(:candidate) { create(:ml_candidates) }
    let!(:metric1) { create(:ml_candidate_metrics, candidate: candidate) }
    let!(:metric2) { create(:ml_candidate_metrics, candidate: candidate) }
    let!(:metric3) { create(:ml_candidate_metrics, name: metric1.name, candidate: candidate) }

    subject { described_class.latest }

    it 'fetches only the last metric for the name' do
      expect(subject).to match_array([metric2, metric3])
    end
  end
end
