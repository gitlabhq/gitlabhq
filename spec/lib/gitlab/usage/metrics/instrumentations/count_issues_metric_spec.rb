# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountIssuesMetric do
  let_it_be(:issue) { create(:issue) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT("issues"."id") FROM "issues"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
