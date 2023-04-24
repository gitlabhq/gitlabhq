# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::PanelPreviewService, feature_category: :metrics do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:panel_yml) do
    <<~YML
    ---
    title: test panel
    YML
  end

  let_it_be(:dashboard) do
    {
      panel_groups: [
        {
          panels: [{ 'title' => 'test panel' }]
        }
      ]
    }
  end

  describe '#execute' do
    subject(:service_response) { described_class.new(project, panel_yml, environment).execute }

    context "valid panel's yaml" do
      before do
        allow_next_instance_of(::Gitlab::Metrics::Dashboard::Processor) do |processor|
          allow(processor).to receive(:process).and_return(dashboard)
        end
      end

      it 'returns success service response' do
        expect(service_response.success?).to be_truthy
      end

      it 'returns processed panel' do
        expect(service_response.payload).to eq('title' => 'test panel')
      end

      it 'uses dashboard processor' do
        sequence = [
          ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
          ::Gitlab::Metrics::Dashboard::Stages::MetricEndpointInserter,
          ::Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter,
          ::Gitlab::Metrics::Dashboard::Stages::UrlValidator
        ]
        processor_params = [project, dashboard, sequence, environment: environment]

        expect_next_instance_of(::Gitlab::Metrics::Dashboard::Processor, *processor_params) do |processor|
          expect(processor).to receive(:process).and_return(dashboard)
        end

        service_response
      end
    end

    context "invalid  panel's yaml" do
      [
        Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError,
        Gitlab::Config::Loader::Yaml::NotHashError,
        Gitlab::Config::Loader::Yaml::DataTooLargeError,
        Gitlab::Config::Loader::FormatError
      ].each do |error_class|
        context "with #{error_class}" do
          before do
            allow_next_instance_of(::Gitlab::Metrics::Dashboard::Processor) do |processor|
              allow(processor).to receive(:process).and_raise(error_class.new('error'))
            end
          end

          it 'returns error service response' do
            expect(service_response.error?).to be_truthy
          end

          it 'returns error message' do
            expect(service_response.message).to eq('error')
          end
        end
      end
    end
  end
end
