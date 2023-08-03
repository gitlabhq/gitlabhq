# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    let(:arguments) { {} }

    subject { described_class.call(arguments) }

    it { is_expected.to be Metrics::Dashboard::SystemDashboardService }

    context 'when just the dashboard path is provided' do
      context 'when the path is for the system dashboard' do
        let(:arguments) { { dashboard_path: system_dashboard_path } }

        it { is_expected.to be Metrics::Dashboard::SystemDashboardService }
      end
    end
  end
end
