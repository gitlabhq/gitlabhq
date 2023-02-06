# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountMlExperimentsMetric, feature_category: :mlops do
  let_it_be(:candidate) { create(:ml_experiments) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT("ml_experiments"."id") FROM "ml_experiments"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
