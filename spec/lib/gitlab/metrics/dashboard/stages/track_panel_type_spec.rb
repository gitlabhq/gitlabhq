# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::TrackPanelType do
  include MetricsDashboardHelpers

  let(:project) { build_stubbed(:project) }
  let(:environment) { build_stubbed(:environment, project: project) }

  describe '#transform!' do
    subject { described_class.new(project, dashboard, environment: environment) }

    let(:dashboard) { load_sample_dashboard.deep_symbolize_keys }

    it 'creates tracking event' do
      expect(Gitlab::Tracking).to receive(:event).with('MetricsDashboard::Chart', 'chart_rendered',
        { label: 'Chart Type', value: 'area-chart' }).at_least(:once)

      subject.transform!
    end
  end
end
