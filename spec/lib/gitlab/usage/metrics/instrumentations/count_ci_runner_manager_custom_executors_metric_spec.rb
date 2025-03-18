# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnerManagerCustomExecutorsMetric,
  feature_category: :runner do
  let_it_be(:docker_executor) { create(:ci_runner_machine, executor_type: :custom) }
  let(:expected_value) { 1 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
