# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithMlExperimentsMetric,
  feature_category: :mlops do
  let_it_be(:project_without_experiment) { create(:project, :repository) }
  let_it_be(:experiment) { create(:ml_experiments) }
  let_it_be(:another_experiment) { create(:ml_experiments, project: experiment.project) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT(DISTINCT "ml_experiments"."project_id") FROM "ml_experiments"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
