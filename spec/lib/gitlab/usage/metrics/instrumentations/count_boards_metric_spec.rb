# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountBoardsMetric do
  let_it_be(:board) { create(:board) }

  let(:expected_value) { 1 }
  let(:expected_query) { 'SELECT COUNT("boards"."id") FROM "boards"' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
