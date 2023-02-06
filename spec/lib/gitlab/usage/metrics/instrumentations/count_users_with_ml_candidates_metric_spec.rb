# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersWithMlCandidatesMetric, feature_category: :mlops do
  let_it_be(:user_without_candidates) { create(:user) }
  let_it_be(:candidate) { create(:ml_candidates) }
  let_it_be(:another_candidate) { create(:ml_candidates, user: candidate.user) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT(DISTINCT "ml_candidates"."user_id") FROM "ml_candidates"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
