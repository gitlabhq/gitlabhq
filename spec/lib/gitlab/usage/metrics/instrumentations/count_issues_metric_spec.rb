# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountIssuesMetric do
  let_it_be(:issue) { create(:issue) }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }, 1
end
