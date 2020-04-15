# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter do
  let(:project) { build_stubbed(:project) }

  def fetch_panel_ids(dashboard_hash)
    dashboard_hash[:panel_groups].flat_map { |group| group[:panels].flat_map { |panel| panel[:id] } }
  end

  describe '#transform!' do
    subject(:transform!) { described_class.new(project, dashboard, nil).transform! }

    let(:dashboard) { YAML.safe_load(fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml')).deep_symbolize_keys }

    context 'when dashboard panels are present' do
      it 'assigns unique ids to each panel using PerformanceMonitoring::PrometheusPanel', :aggregate_failures do
        dashboard.fetch(:panel_groups).each do |group|
          group.fetch(:panels).each do |panel|
            panel_double = instance_double(::PerformanceMonitoring::PrometheusPanel)

            expect(::PerformanceMonitoring::PrometheusPanel).to receive(:new).with(panel).and_return(panel_double)
            expect(panel_double).to receive(:id).with(group[:group]).and_return(FFaker::Lorem.unique.characters(125))
          end
        end

        transform!

        expect(fetch_panel_ids(dashboard)).not_to include nil
      end
    end

    context 'when dashboard panels has duplicated ids' do
      it 'no panel has assigned id' do
        panel_double = instance_double(::PerformanceMonitoring::PrometheusPanel)
        allow(::PerformanceMonitoring::PrometheusPanel).to receive(:new).and_return(panel_double)
        allow(panel_double).to receive(:id).and_return('duplicated id')

        transform!

        expect(fetch_panel_ids(dashboard)).to all be_nil
        expect(fetch_panel_ids(dashboard)).not_to include 'duplicated id'
      end
    end

    context 'when there are no panels in the dashboard' do
      it 'raises a processing error' do
        dashboard[:panel_groups][0].delete(:panels)

        expect { transform! }.to(
          raise_error(::Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError)
        )
      end
    end

    context 'when there are no panel_groups in the dashboard' do
      it 'raises a processing error' do
        dashboard.delete(:panel_groups)

        expect { transform! }.to(
          raise_error(::Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError)
        )
      end
    end

    context 'when dashboard panels has unknown schema attributes' do
      before do
        error = ActiveModel::UnknownAttributeError.new(double, 'unknown_panel_attribute')
        allow(::PerformanceMonitoring::PrometheusPanel).to receive(:new).and_raise(error)
      end

      it 'no panel has assigned id' do
        transform!

        expect(fetch_panel_ids(dashboard)).to all be_nil
      end

      it 'logs the failure' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)

        transform!
      end
    end
  end
end
