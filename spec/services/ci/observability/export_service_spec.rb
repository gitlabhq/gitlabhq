# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Observability::ExportService, feature_category: :observability do
  let_it_be(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:service) { described_class.new(pipeline) }

  shared_context 'with pipeline variables setup' do
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:variables_collection) { instance_double(Gitlab::Ci::Variables::Collection) }
    let(:variables_builder) { instance_double(Gitlab::Ci::Variables::Builder) }
    let(:builds_relation) { instance_spy(ActiveRecord::Relation, first: build) }

    before do
      allow(pipeline).to receive_messages(builds: builds_relation, variables_builder: variables_builder)
      allow(variables_builder).to receive(:scoped_variables).with(
        build,
        environment: nil,
        dependencies: false
      ).and_return(variables_collection)
    end
  end

  shared_context 'with observability settings' do |url|
    let(:observability_settings) do
      instance_double(Observability::GroupO11ySetting, otel_http_endpoint: url || 'http://example.com')
    end

    before do
      allow(Observability::GroupO11ySetting).to receive(:observability_settings_for)
        .with(project)
        .and_return(observability_settings)
    end
  end

  def create_export_variable(value)
    instance_double(Gitlab::Ci::Variables::Collection::Item,
      key: described_class::OBSERVABILITY_VARIABLE,
      value: value,
      to_s: value)
  end

  describe '#execute' do
    context 'when CI variable is not set' do
      before do
        allow(service).to receive(:should_export?).and_return(false)
      end

      it 'does not export data' do
        expect(service).not_to receive(:export_data)
        service.execute
      end
    end

    context 'when observability settings are not present' do
      before do
        allow(service).to receive(:should_export?).and_return(true)
        allow(Observability::GroupO11ySetting).to receive(:observability_settings_for)
          .with(project)
          .and_return(nil)
      end

      it 'does not export data' do
        expect(service).not_to receive(:export_data)
        service.execute
      end
    end

    context 'when observability settings are present and CI variable is set' do
      include_context 'with observability settings'

      before do
        allow(service).to receive(:should_export?).and_return(true)
        allow(service).to receive(:export_data)
      end

      it 'exports data' do
        expect(service).to receive(:export_data)
        service.execute
      end
    end

    context 'when an error occurs' do
      include_context 'with observability settings'

      before do
        allow(service).to receive(:should_export?).and_return(true)
        allow(service).to receive(:export_data).and_raise(StandardError, 'Test error')
      end

      it 'logs the error and does not raise' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: "GitLab Observability export failed",
            pipeline_id: pipeline.id,
            project_id: pipeline.project_id,
            error_class: 'StandardError',
            error_message: 'Test error'
          )
        )

        expect { service.execute }.not_to raise_error
      end
    end
  end

  describe '#should_export?' do
    include_context 'with pipeline variables setup'

    context 'when CI variable has a value' do
      let(:export_variable) { create_export_variable('traces,metrics') }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
      end

      it 'returns true' do
        expect(service.send(:should_export?)).to be_truthy
      end
    end

    context 'when CI variable is not set' do
      before do
        allow(variables_collection).to receive(:find).and_return(nil)
      end

      it 'returns false' do
        expect(service.send(:should_export?)).to be_falsy
      end
    end

    context 'when CI variable is empty' do
      let(:export_variable) { create_export_variable('') }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
      end

      it 'returns false' do
        expect(service.send(:should_export?)).to be_falsy
      end
    end
  end

  describe '#export_types' do
    include_context 'with pipeline variables setup'

    context 'when CI variable has traces and metrics' do
      let(:export_variable) { create_export_variable('traces,metrics') }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
      end

      it 'returns traces and metrics' do
        expect(service.send(:export_types)).to contain_exactly('traces', 'metrics')
      end
    end

    context 'when CI variable has invalid values' do
      let(:export_variable) { create_export_variable('traces,invalid,metrics') }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
      end

      it 'returns only valid values' do
        expect(service.send(:export_types)).to contain_exactly('traces', 'metrics')
      end
    end

    context 'when CI variable is not set' do
      before do
        allow(variables_collection).to receive(:find).and_return(nil)
      end

      it 'returns empty array' do
        expect(service.send(:export_types)).to eq([])
      end
    end

    context 'when build is nil' do
      let(:limited_relation) { instance_spy(ActiveRecord::Relation, first: nil) }
      let(:builds_relation) { instance_spy(ActiveRecord::Relation) }

      before do
        allow(pipeline).to receive(:builds).and_return(builds_relation)
        allow(builds_relation).to receive(:limit).with(1).and_return(limited_relation)
      end

      it 'returns empty array' do
        expect(service.send(:export_types)).to eq([])
      end
    end
  end

  describe '#export_data' do
    include_context 'with pipeline variables setup'
    include_context 'with observability settings'

    let(:pipeline_data) { { object_attributes: { id: pipeline.id }, builds: [] } }
    let(:exporter) { instance_double(Gitlab::Observability::OtelExporter) }
    let(:integration) { instance_double(Struct) }

    before do
      allow(Gitlab::DataBuilder::Pipeline).to receive(:build).with(pipeline).and_return(pipeline_data)
      allow(service).to receive_messages(integration: integration, exporter: exporter)
    end

    shared_examples 'exports data type' do |export_type, converter_class, export_method|
      let(:export_variable) { create_export_variable(export_type) }
      let(:converter) { instance_double(converter_class) }
      let(:converted_data) { { data: [] } }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
        allow(converter_class).to receive(:new)
          .with(integration, pipeline_data)
          .and_return(converter)
        allow(converter).to receive(:convert).and_return(converted_data)
        allow(exporter).to receive(export_method)
      end

      it "calls #{export_method} with converted data" do
        expect(converter_class).to receive(:new).with(integration, pipeline_data).and_return(converter)
        expect(converter).to receive(:convert).and_return(converted_data)
        expect(exporter).to receive(export_method).with(converted_data)
        service.send(:export_data)
      end
    end

    it 'builds pipeline data' do
      allow(variables_collection).to receive(:find).and_return(create_export_variable('traces'))
      allow(Gitlab::Observability::PipelineToTraces).to receive(:new).and_return(instance_double(
        Gitlab::Observability::PipelineToTraces, convert: {}))
      allow(exporter).to receive(:export_traces)

      expect(Gitlab::DataBuilder::Pipeline).to receive(:build).with(pipeline)
      service.send(:export_data)
    end

    it_behaves_like 'exports data type', 'traces', Gitlab::Observability::PipelineToTraces, :export_traces
    it_behaves_like 'exports data type', 'metrics', Gitlab::Observability::PipelineToMetrics, :export_metrics
    it_behaves_like 'exports data type', 'logs', Gitlab::Observability::PipelineToLogs, :export_logs

    context 'when multiple export types are specified' do
      let(:export_variable) { create_export_variable('traces,metrics,logs') }
      let(:traces_converter) { instance_double(Gitlab::Observability::PipelineToTraces) }
      let(:metrics_converter) { instance_double(Gitlab::Observability::PipelineToMetrics) }
      let(:logs_converter) { instance_double(Gitlab::Observability::PipelineToLogs) }
      let(:traces_data) { { spans: [] } }
      let(:metrics_data) { { metrics: [] } }
      let(:logs_data) { { logs: [] } }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
        allow(Gitlab::Observability::PipelineToTraces).to receive(:new)
          .with(integration, pipeline_data).and_return(traces_converter)
        allow(Gitlab::Observability::PipelineToMetrics).to receive(:new)
          .with(integration, pipeline_data).and_return(metrics_converter)
        allow(Gitlab::Observability::PipelineToLogs).to receive(:new)
          .with(integration, pipeline_data).and_return(logs_converter)
        allow(traces_converter).to receive(:convert).and_return(traces_data)
        allow(metrics_converter).to receive(:convert).and_return(metrics_data)
        allow(logs_converter).to receive(:convert).and_return(logs_data)
        allow(exporter).to receive(:export_traces)
        allow(exporter).to receive(:export_metrics)
        allow(exporter).to receive(:export_logs)
      end

      it 'builds pipeline data once' do
        expect(Gitlab::DataBuilder::Pipeline).to receive(:build).with(pipeline).once
        service.send(:export_data)
      end

      it 'calls all export methods' do
        expect(exporter).to receive(:export_traces).with(traces_data)
        expect(exporter).to receive(:export_metrics).with(metrics_data)
        expect(exporter).to receive(:export_logs).with(logs_data)
        service.send(:export_data)
      end
    end

    context 'when converter returns empty data' do
      let(:export_variable) { create_export_variable('traces') }
      let(:traces_converter) { instance_double(Gitlab::Observability::PipelineToTraces) }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
        allow(Gitlab::Observability::PipelineToTraces).to receive(:new)
          .with(integration, pipeline_data).and_return(traces_converter)
        allow(traces_converter).to receive(:convert).and_return(nil)
      end

      it 'does not call exporter when data is empty' do
        expect(exporter).not_to receive(:export_traces)
        service.send(:export_data)
      end
    end

    context 'when metrics converter returns empty data' do
      let(:export_variable) { create_export_variable('metrics') }
      let(:metrics_converter) { instance_double(Gitlab::Observability::PipelineToMetrics) }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
        allow(Gitlab::Observability::PipelineToMetrics).to receive(:new)
          .with(integration, pipeline_data).and_return(metrics_converter)
        allow(metrics_converter).to receive(:convert).and_return(nil)
      end

      it 'does not call exporter when metrics data is empty' do
        expect(exporter).not_to receive(:export_metrics)
        service.send(:export_data)
      end
    end

    context 'when logs converter returns empty data' do
      let(:export_variable) { create_export_variable('logs') }
      let(:logs_converter) { instance_double(Gitlab::Observability::PipelineToLogs) }

      before do
        allow(variables_collection).to receive(:find).and_return(export_variable)
        allow(Gitlab::Observability::PipelineToLogs).to receive(:new)
          .with(integration, pipeline_data).and_return(logs_converter)
        allow(logs_converter).to receive(:convert).and_return(nil)
      end

      it 'does not call exporter when logs data is empty' do
        expect(exporter).not_to receive(:export_logs)
        service.send(:export_data)
      end
    end

    context 'when export_type does not match any case branch' do
      before do
        allow(service).to receive(:export_types).and_return(['unknown_type'])
      end

      it 'does not call any export methods' do
        expect(exporter).not_to receive(:export_traces)
        expect(exporter).not_to receive(:export_metrics)
        expect(exporter).not_to receive(:export_logs)
        service.send(:export_data)
      end
    end
  end

  describe '#integration' do
    include_context 'with observability settings', 'http://test.example.com'

    it 'returns a Struct with correct fields and values' do
      integration = service.send(:integration)

      expect(integration).to be_a(Struct)
      expect(integration.otel_endpoint_url).to eq('http://test.example.com')
      expect(integration.otel_headers).to eq({})
      expect(integration.service_name).to eq('gitlab-ci')
      expect(integration.environment).to eq(Rails.env)
    end
  end

  describe '#exporter' do
    include_context 'with observability settings'

    it 'creates a new OtelExporter with the integration' do
      integration = service.send(:integration)
      expect(Gitlab::Observability::OtelExporter).to receive(:new).with(integration).and_call_original

      expect(service.send(:exporter)).to be_a(Gitlab::Observability::OtelExporter)
    end

    it 'memoizes the exporter' do
      exporter1 = service.send(:exporter)
      exporter2 = service.send(:exporter)

      expect(exporter1).to be(exporter2)
    end
  end
end
