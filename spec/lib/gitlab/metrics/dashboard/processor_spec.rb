# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Processor do
  include MetricsDashboardHelpers

  let(:project) { build(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:dashboard_yml) { load_sample_dashboard }

  describe 'process' do
    let(:sequence) do
      [
        Gitlab::Metrics::Dashboard::Stages::UrlValidator
      ]
    end

    let(:process_params) { [project, dashboard_yml, sequence, { environment: environment }] }
    let(:dashboard) { described_class.new(*process_params).process }

    context 'when the dashboard is not present' do
      let(:dashboard_yml) { nil }

      it 'returns nil' do
        expect(dashboard).to be_nil
      end
    end
  end
end
