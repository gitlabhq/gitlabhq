# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithMlCandidatesMetric,
  feature_category: :mlops do
  let_it_be(:project_without_candidates) { create(:project, :repository) }
  let_it_be(:candidate) { create(:ml_candidates) }
  let_it_be(:another_candidate) { create(:ml_candidates, experiment: candidate.experiment) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "ml_experiments"."ml_experiments.project_id") FROM "ml_experiments" WHERE ' \
      '(EXISTS (SELECT 1 FROM "ml_candidates" WHERE ("ml_experiments"."id" = "ml_candidates"."experiment_id")))'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
