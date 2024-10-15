# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnersProjectTypeActiveOnlineMetric, feature_category: :runner do
  let_it_be(:project) { create(:project) }

  let(:expected_value) { 1 }

  before do
    create(:ci_runner, :project, projects: [project], contacted_at: 1.second.ago)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
