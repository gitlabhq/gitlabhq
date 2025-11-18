# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnersProjectTypeActiveOnlineMetric, feature_category: :runner_core do
  let_it_be(:project) { create(:project) }

  let(:expected_value) { 1 }

  before do
    create(:ci_runner)
    create(:ci_runner, :project, :online, projects: [project])
    create(:ci_runner, :project, :online, :paused, projects: [project])
    create(:ci_runner, :project, :offline, projects: [project])
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
