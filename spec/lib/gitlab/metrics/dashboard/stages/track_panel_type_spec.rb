# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::TrackPanelType do
  include MetricsDashboardHelpers

  let(:project) { build_stubbed(:project) }
  let(:environment) { build_stubbed(:environment, project: project) }

  describe '#transform!', :snowplow do
    subject { described_class.new(project, dashboard, environment: environment) }

    let(:dashboard) { load_sample_dashboard.deep_symbolize_keys }

    it 'creates tracking event' do
      subject.transform!

      expect_snowplow_event(
        category: 'MetricsDashboard::Chart',
        action: 'chart_rendered',
        label: 'area-chart'
      )
    end
  end
end
