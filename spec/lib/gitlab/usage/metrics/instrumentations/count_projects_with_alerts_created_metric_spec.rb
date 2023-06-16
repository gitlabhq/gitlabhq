# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithAlertsCreatedMetric, feature_category: :service_ping do
  before do
    project = create(:project)
    create(:alert_management_alert, project: project, created_at: 5.days.ago)
    create(:alert_management_alert, project: project, created_at: 10.days.ago)
    create(:alert_management_alert, created_at: 1.year.ago)
  end

  context 'with 28d timeframe' do
    let(:expected_value) { 1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d' }
  end

  context 'with all timeframe' do
    let(:expected_value) { 2 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
  end
end
