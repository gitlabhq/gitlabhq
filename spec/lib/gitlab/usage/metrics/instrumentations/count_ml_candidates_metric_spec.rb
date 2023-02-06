# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountMlCandidatesMetric, feature_category: :mlops do
  let_it_be(:candidate) { create(:ml_candidates) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT("ml_candidates"."id") FROM "ml_candidates"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
