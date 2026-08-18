# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/gitlab/ci/trace_context'
require_relative '../../../support/shared_contexts/lib/gitlab/observability/pipeline_converter_shared_context'

RSpec.describe Gitlab::Observability::PipelineToTraces, feature_category: :observability do
  include_context 'with pipeline converter data'

  let(:pipeline_data) do
    base_pipeline_data.deep_merge(
      object_attributes: {
        root_pipeline_id: 100
      }
    )
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  def convert_result
    converter.convert
  end

  def spans
    convert_result[:resourceSpans].first[:scopeSpans].first[:spans]
  end

  def pipeline_span
    spans.find { |span| span[:name].start_with?('pipeline:') }
  end

  def job_span
    spans.find { |span| span[:name].start_with?('job:') && span[:name].include?('test-job') }
  end

  def resource
    convert_result[:resourceSpans].first[:resource]
  end

  describe '#convert' do
    it 'returns valid OTEL traces format' do
      result = convert_result

      aggregate_failures do
        expect(result).to have_key(:resourceSpans)
        expect(result[:resourceSpans]).to be_an(Array)
        expect(result[:resourceSpans].length).to eq(1)
      end
    end

    it 'includes resource attributes' do
      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
        { key: 'vcs.repository.name', value: { stringValue: 'test-project' } }
      )
    end

    it 'includes pipeline span' do
      aggregate_failures do
        expect(pipeline_span).to be_present
        expect(pipeline_span[:name]).to eq('pipeline: test-pipeline')
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_OK')
      end
    end

    it 'sets correct timestamps' do
      aggregate_failures do
        expect(pipeline_span[:startTimeUnixNano]).to eq(1672567200000000000)
        expect(pipeline_span[:endTimeUnixNano]).to eq(1672567500000000000)
      end
    end

    it 'handles failed job status' do
      pipeline_data[:builds].first[:status] = 'failed'
      pipeline_data[:builds].first[:failure_reason] = 'runner_system_failure'

      aggregate_failures do
        expect(job_span[:status][:code]).to eq('STATUS_CODE_ERROR')
        expect(job_span[:status][:message]).to eq('runner_system_failure')
      end
    end

    it 'handles unhandled pipeline status with STATUS_CODE_UNSET' do
      pipeline_data[:object_attributes][:status] = 'running'

      expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_UNSET')
    end

    it 'does not include status message when failure_reason is absent' do
      aggregate_failures do
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_OK')
        expect(pipeline_span[:status]).not_to have_key(:message)
      end
    end

    it 'includes job legacy attributes' do
      expect(job_span[:attributes]).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.runner.description', value: { stringValue: 'test-runner' } }
      )
    end

    it 'handles empty pipeline data' do
      converter = described_class.new(integration, {})
      result = converter.convert

      expect(result[:resourceSpans]).to be_empty
    end

    it 'handles missing timestamps gracefully' do
      pipeline_data[:object_attributes].delete(:created_at)
      pipeline_data[:object_attributes].delete(:finished_at)

      aggregate_failures do
        expect(pipeline_span[:startTimeUnixNano]).to eq(0)
        expect(pipeline_span[:endTimeUnixNano]).to eq(0)
      end
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end

    it 'sets up trace and span IDs correctly' do
      expected_root_pipeline_id = pipeline_data.dig(:object_attributes, :root_pipeline_id)
      expected_trace_id_val = Gitlab::Ci::TraceContext.trace_id_for(expected_root_pipeline_id)
      expected_pipeline_span_id_val = Gitlab::Ci::TraceContext.span_id_for_pipeline(
        expected_root_pipeline_id, pipeline_data.dig(:object_attributes, :id)
      )

      job_spans = spans.select { |span| span[:name].start_with?('job:') }

      aggregate_failures do
        expect(pipeline_span[:traceId]).to eq(expected_trace_id_val)
        expect(pipeline_span[:traceId].length).to eq(32)
        expect(pipeline_span[:spanId]).to eq(expected_pipeline_span_id_val)
        expect(pipeline_span[:spanId].length).to eq(16)
        expect(pipeline_span[:parentSpanId]).to eq('')
      end

      job_spans.each do |span|
        build = pipeline_data[:builds].find { |b| span[:name] == "job: #{b[:name]}" }
        expected_job_span_id = Gitlab::Ci::TraceContext.span_id_for_job(
          expected_root_pipeline_id, build[:id], :export
        )

        aggregate_failures do
          expect(span[:traceId]).to eq(pipeline_span[:traceId])
          expect(span[:spanId]).to eq(expected_job_span_id)
          expect(span[:spanId].length).to eq(16)
          expect(span[:parentSpanId]).to eq(pipeline_span[:spanId])
        end
      end

      all_span_ids = [pipeline_span[:spanId]] + job_spans.pluck(:spanId)
      expect(all_span_ids.uniq.length).to eq(all_span_ids.length)
    end

    it 'produces deterministic output for the same input' do
      result1 = converter.convert
      result2 = described_class.new(integration, pipeline_data).convert

      expect(result1).to eq(result2)
    end

    context 'with root_pipeline_id present' do
      it 'uses root_pipeline_id for trace_id' do
        expected = Gitlab::Ci::TraceContext.trace_id_for(100)

        expect(pipeline_span[:traceId]).to eq(expected)
      end

      it 'shares trace_id across sibling pipelines with same root' do
        sibling_data = pipeline_data.deep_dup
        sibling_data[:object_attributes][:id] = 456
        sibling_data[:object_attributes][:root_pipeline_id] = 100

        sibling_converter = described_class.new(integration, sibling_data)
        sibling_spans = sibling_converter.convert[:resourceSpans].first[:scopeSpans].first[:spans]
        sibling_pipeline_span = sibling_spans.find { |s| s[:name].start_with?('pipeline:') }

        aggregate_failures do
          expect(sibling_pipeline_span[:traceId]).to eq(pipeline_span[:traceId])
          expect(sibling_pipeline_span[:spanId]).not_to eq(pipeline_span[:spanId])
        end
      end
    end

    context 'without root_pipeline_id' do
      before do
        pipeline_data[:object_attributes].delete(:root_pipeline_id)
      end

      it 'falls back to pipeline id for trace_id' do
        pipeline_id = pipeline_data.dig(:object_attributes, :id)

        expect(pipeline_span[:traceId]).to eq(Gitlab::Ci::TraceContext.trace_id_for(pipeline_id))
      end
    end

    context 'when source_pipeline present but root_pipeline_id absent' do
      before do
        pipeline_data[:trace_correlation_enabled] = true
        pipeline_data[:source_pipeline] = { pipeline_id: 999 }
        pipeline_data[:object_attributes].delete(:root_pipeline_id)
      end

      it 'logs a warning and falls back to pipeline id' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(message: 'root_pipeline_id missing from pipeline webhook payload with source_pipeline present')
        )

        pipeline_id = pipeline_data.dig(:object_attributes, :id)
        expect(pipeline_span[:traceId]).to eq(Gitlab::Ci::TraceContext.trace_id_for(pipeline_id))
      end
    end

    context 'with same-project source pipeline (cross-pipeline linking)' do
      before do
        pipeline_data[:trace_correlation_enabled] = true
        pipeline_data[:source_pipeline] = {
          project: { id: 789 },
          bridge_id: 50,
          pipeline_id: 100
        }
      end

      it 'sets parentSpanId to the bridge job deterministic span ID' do
        expect(pipeline_span[:parentSpanId]).to eq(Gitlab::Ci::TraceContext.span_id_for_bridge(50))
      end
    end

    context 'with cross-project source pipeline' do
      before do
        pipeline_data[:trace_correlation_enabled] = true
        pipeline_data[:source_pipeline] = {
          project: { id: 999 },
          bridge_id: 50,
          pipeline_id: 100
        }
      end

      it 'does not set parentSpanId when source is a different project' do
        expect(pipeline_span[:parentSpanId]).to eq('')
      end
    end

    context 'with no source pipeline' do
      it 'leaves parentSpanId empty' do
        expect(pipeline_span[:parentSpanId]).to eq('')
      end
    end

    context 'with trace_correlation_enabled false' do
      before do
        pipeline_data[:trace_correlation_enabled] = false
        pipeline_data[:source_pipeline] = { project: { id: 789 }, bridge_id: 50, pipeline_id: 100 }
      end

      it 'leaves parentSpanId empty' do
        expect(pipeline_span[:parentSpanId]).to eq('')
      end
    end

    context 'with source pipeline but no bridge_id' do
      before do
        pipeline_data[:trace_correlation_enabled] = true
        pipeline_data[:source_pipeline] = { project: { id: 789 }, bridge_id: nil, pipeline_id: 100 }
      end

      it 'leaves parentSpanId empty' do
        expect(pipeline_span[:parentSpanId]).to eq('')
      end
    end

    context 'with optional pipeline attributes' do
      before do
        pipeline_data[:object_attributes][:tag] = true
        pipeline_data[:object_attributes][:before_sha] = 'def456'
        pipeline_data[:object_attributes][:stages] = %w[build test deploy]
        pipeline_data[:user] = { id: 42, username: 'testuser' }
        pipeline_data[:commit] = { id: 'abc123', message: 'Test commit' }
        pipeline_data[:merge_request] = { id: 100, iid: 10 }
        pipeline_data[:source_pipeline] = { pipeline_id: 999 }
      end

      it 'includes optional pipeline attributes when present' do
        attributes = pipeline_span[:attributes]

        expect(attributes).to include(
          { key: 'pipeline.tag', value: { boolValue: true } },
          { key: 'pipeline.before_sha', value: { stringValue: 'def456' } },
          { key: 'pipeline.stages', value: { arrayValue: { values: [
            { stringValue: 'build' },
            { stringValue: 'test' },
            { stringValue: 'deploy' }
          ] } } },
          { key: 'gitlab.cicd.pipeline.stages', value: { arrayValue: { values: [
            { stringValue: 'build' },
            { stringValue: 'test' },
            { stringValue: 'deploy' }
          ] } } },
          { key: 'pipeline.user.id', value: { intValue: 42 } },
          { key: 'pipeline.user.username', value: { stringValue: 'testuser' } },
          { key: 'pipeline.commit.id', value: { stringValue: 'abc123' } },
          { key: 'pipeline.commit.message', value: { stringValue: 'Test commit' } },
          { key: 'pipeline.merge_request.id', value: { intValue: 100 } },
          { key: 'pipeline.merge_request.iid', value: { intValue: 10 } },
          { key: 'pipeline.source_pipeline.pipeline_id', value: { intValue: 999 } }
        )
      end
    end

    context 'with optional job attributes' do
      before do
        pipeline_data[:builds].first[:created_at] = Time.zone.parse('2023-01-01T10:00:30Z')
        pipeline_data[:builds].first[:when] = 'on_success'
        pipeline_data[:builds].first[:user] = { id: 43, username: 'jobuser' }
        pipeline_data[:builds].first[:artifacts_file] = { filename: 'artifact.zip', size: 1024 }
        pipeline_data[:builds].first[:runner][:runner_type] = 'instance_type'
        pipeline_data[:builds].first[:runner][:active] = true
        pipeline_data[:builds].first[:runner][:is_shared] = true
        pipeline_data[:builds].first[:environment] = {
          name: 'production',
          action: 'start',
          deployment_tier: 'production'
        }
      end

      it 'includes optional job attributes when present' do
        expect(job_span[:attributes]).to include(
          { key: 'job.created_at', value: { intValue: 1672567230000000000 } },
          { key: 'job.when', value: { stringValue: 'on_success' } },
          { key: 'job.user.id', value: { intValue: 43 } },
          { key: 'job.user.username', value: { stringValue: 'jobuser' } },
          { key: 'job.artifacts.filename', value: { stringValue: 'artifact.zip' } },
          { key: 'job.artifacts.size', value: { intValue: 1024 } },
          { key: 'job.runner.type', value: { stringValue: 'instance_type' } },
          { key: 'job.runner.active', value: { boolValue: true } },
          { key: 'job.runner.is_shared', value: { boolValue: true } },
          { key: 'gitlab.cicd.runner.is_shared', value: { boolValue: true } },
          { key: 'job.environment.deployment_tier', value: { stringValue: 'production' } }
        )
      end
    end

    context 'with bridge job' do
      before do
        pipeline_data[:bridges] = [{
          id: 2,
          name: 'trigger-child',
          stage: 'deploy',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:04:00Z'),
          duration: 60000,
          manual: false,
          allow_failure: false,
          bridge: true
        }]
      end

      it 'marks bridge job with job.type attribute' do
        bridge_span = spans.find { |s| s[:name] == 'job: trigger-child' }

        expect(bridge_span[:attributes]).to include(
          { key: 'job.type', value: { stringValue: 'bridge' } }
        )
      end

      it 'marks bridge job with gitlab.cicd.pipeline.task.kind attribute' do
        bridge_span = spans.find { |s| s[:name] == 'job: trigger-child' }

        expect(bridge_span[:attributes]).to include(
          { key: 'gitlab.cicd.pipeline.task.kind', value: { stringValue: 'bridge' } }
        )
      end

      it 'does not mark regular jobs with job.type' do
        expect(job_span[:attributes].pluck(:key)).not_to include('job.type')
      end

      it 'does not mark regular jobs with gitlab.cicd.pipeline.task.kind' do
        expect(job_span[:attributes].pluck(:key)).not_to include('gitlab.cicd.pipeline.task.kind')
      end

      it 'uses span_id_for_bridge for the bridge span ID' do
        bridge_span = spans.find { |s| s[:name] == 'job: trigger-child' }

        expect(bridge_span[:spanId]).to eq(Gitlab::Ci::TraceContext.span_id_for_bridge(2))
      end

      it 'uses span_id_for_job with :export kind for regular job span IDs' do
        root_id = pipeline_data.dig(:object_attributes, :root_pipeline_id)
        expected = Gitlab::Ci::TraceContext.span_id_for_job(root_id, 1, :export)

        expect(job_span[:spanId]).to eq(expected)
      end

      it 'produces a bridge spanId that matches a child pipeline parentSpanId' do
        bridge_span = spans.find { |s| s[:name] == 'job: trigger-child' }
        child_parent_span_id = Gitlab::Ci::TraceContext.span_id_for_bridge(2)

        expect(bridge_span[:spanId]).to eq(child_parent_span_id)
      end
    end
  end

  describe 'OTel CI/CD semantic conventions' do
    def find_attr(attrs, key)
      attrs.find { |a| a[:key] == key }
    end

    def pipeline_attrs
      pipeline_span[:attributes]
    end

    def job_attrs
      job_span[:attributes]
    end

    def resource_attrs
      resource[:attributes]
    end

    describe 'pipeline cicd.* attributes' do
      it 'emits cicd.pipeline.name' do
        attr = find_attr(pipeline_attrs, 'cicd.pipeline.name')

        expect(attr[:value][:stringValue]).to eq('test-pipeline')
      end

      it 'emits cicd.pipeline.run.id in span attributes' do
        attr = find_attr(pipeline_attrs, 'cicd.pipeline.run.id')

        expect(attr[:value][:stringValue]).to eq('123')
      end

      it 'emits cicd.pipeline.result with mapped value' do
        attr = find_attr(pipeline_attrs, 'cicd.pipeline.result')

        expect(attr[:value][:stringValue]).to eq('success')
      end

      context 'when pipeline status is failed' do
        before do
          pipeline_data[:object_attributes][:status] = 'failed'
        end

        it 'maps to failure' do
          attr = find_attr(pipeline_attrs, 'cicd.pipeline.result')

          expect(attr[:value][:stringValue]).to eq('failure')
        end
      end

      context 'when pipeline status is running' do
        before do
          pipeline_data[:object_attributes][:status] = 'running'
        end

        it 'maps run.state to executing' do
          attr = find_attr(pipeline_attrs, 'cicd.pipeline.run.state')

          expect(attr[:value][:stringValue]).to eq('executing')
        end
      end

      it 'omits cicd.pipeline.result when status is running' do
        pipeline_data[:object_attributes][:status] = 'running'
        keys = pipeline_span[:attributes].map { |a| a[:key] }

        expect(keys).not_to include('cicd.pipeline.result')
      end

      it 'omits cicd.pipeline.run.state when status is terminal' do
        keys = pipeline_span[:attributes].map { |a| a[:key] }

        expect(keys).not_to include('cicd.pipeline.run.state')
      end
    end

    describe 'pipeline gitlab.cicd.* deviation attributes' do
      it 'emits gitlab.cicd.pipeline.trigger.type with raw source' do
        attr = find_attr(pipeline_attrs, 'gitlab.cicd.pipeline.trigger.type')

        expect(attr[:value][:stringValue]).to eq('push')
      end

      it 'omits gitlab.cicd.pipeline.trigger.type when source is nil' do
        pipeline_data[:object_attributes][:source] = nil
        keys = pipeline_span[:attributes].map { |a| a[:key] }

        expect(keys).not_to include('gitlab.cicd.pipeline.trigger.type')
      end

      it 'emits gitlab.cicd.pipeline.run.queued_duration' do
        attr = find_attr(pipeline_attrs, 'gitlab.cicd.pipeline.run.queued_duration')

        expect(attr[:value][:intValue]).to eq(30000)
      end

      it 'emits gitlab.cicd.pipeline.run.duration' do
        attr = find_attr(pipeline_attrs, 'gitlab.cicd.pipeline.run.duration')

        expect(attr[:value][:intValue]).to eq(300000)
      end

      it 'emits gitlab.vcs.ref.head.protected' do
        attr = find_attr(pipeline_attrs, 'gitlab.vcs.ref.head.protected')

        expect(attr[:value][:boolValue]).to be(true)
      end

      it 'emits gitlab.cicd.pipeline.stages when stages present' do
        pipeline_data[:object_attributes][:stages] = %w[build test deploy]
        attr = find_attr(pipeline_attrs, 'gitlab.cicd.pipeline.stages')
        values = attr[:value][:arrayValue][:values].map { |v| v[:stringValue] }

        expect(values).to eq(%w[build test deploy])
      end
    end

    describe 'pipeline vcs.* span attributes' do
      it 'emits vcs.ref.head.name' do
        attr = find_attr(pipeline_attrs, 'vcs.ref.head.name')

        expect(attr[:value][:stringValue]).to eq('main')
      end

      it 'emits vcs.ref.head.revision' do
        attr = find_attr(pipeline_attrs, 'vcs.ref.head.revision')

        expect(attr[:value][:stringValue]).to eq('abc123')
      end

      it 'emits vcs.ref.head.type as branch' do
        attr = find_attr(pipeline_attrs, 'vcs.ref.head.type')

        expect(attr[:value][:stringValue]).to eq('branch')
      end

      it 'emits vcs.ref.head.type as tag when pipeline is a tag' do
        pipeline_data[:object_attributes][:tag] = true
        attr = find_attr(pipeline_attrs, 'vcs.ref.head.type')

        expect(attr[:value][:stringValue]).to eq('tag')
      end

      it 'emits vcs.ref.base.revision when before_sha is present' do
        pipeline_data[:object_attributes][:before_sha] = 'def456'
        attr = find_attr(pipeline_attrs, 'vcs.ref.base.revision')

        expect(attr[:value][:stringValue]).to eq('def456')
      end
    end

    describe 'job cicd.pipeline.task.* attributes' do
      it 'emits cicd.pipeline.task.name' do
        attr = find_attr(job_attrs, 'cicd.pipeline.task.name')

        expect(attr[:value][:stringValue]).to eq('test-job')
      end

      it 'emits cicd.pipeline.task.run.id' do
        attr = find_attr(job_attrs, 'cicd.pipeline.task.run.id')

        expect(attr[:value][:stringValue]).to eq('1')
      end

      it 'emits cicd.pipeline.task.run.result' do
        attr = find_attr(job_attrs, 'cicd.pipeline.task.run.result')

        expect(attr[:value][:stringValue]).to eq('success')
      end

      it 'emits cicd.pipeline.task.run.url.full' do
        attr = find_attr(job_attrs, 'cicd.pipeline.task.run.url.full')

        expect(attr[:value][:stringValue]).to eq('https://gitlab.com/test-org/test-project/-/jobs/1')
      end

      it 'emits cicd.pipeline.task.type from stage' do
        attr = find_attr(job_attrs, 'cicd.pipeline.task.type')

        expect(attr[:value][:stringValue]).to eq('test')
      end

      it 'includes cicd.pipeline.task.type with raw stage value' do
        pipeline_data[:builds].first[:stage] = 'deploy'
        keys = job_span[:attributes].map { |a| a[:key] }

        expect(keys).to include('cicd.pipeline.task.type')
        attr = job_span[:attributes].find { |a| a[:key] == 'cicd.pipeline.task.type' }
        expect(attr[:value][:stringValue]).to eq('deploy')
      end
    end

    describe 'job gitlab.cicd.pipeline.task.* deviation attributes' do
      it 'emits gitlab.cicd.pipeline.task.allow_failure' do
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.allow_failure')

        expect(attr[:value][:boolValue]).to be(false)
      end

      it 'emits gitlab.cicd.pipeline.task.run.failure_reason when present' do
        pipeline_data[:builds].first[:failure_reason] = 'script_failure'
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.run.failure_reason')

        expect(attr[:value][:stringValue]).to eq('script_failure')
      end

      it 'emits gitlab.cicd.pipeline.task.trigger.type with raw source' do
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.trigger.type')

        expect(attr[:value][:stringValue]).to eq('push')
      end

      it 'emits gitlab.cicd.pipeline.task.trigger.type with raw source for manual jobs' do
        pipeline_data[:builds].first[:manual] = true
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.trigger.type')

        expect(attr[:value][:stringValue]).to eq('push')
      end

      it 'emits gitlab.cicd.pipeline.task.run.queued_duration' do
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.run.queued_duration')

        expect(attr[:value][:intValue]).to eq(5000)
      end

      it 'emits gitlab.cicd.pipeline.task.run.duration' do
        attr = find_attr(job_attrs, 'gitlab.cicd.pipeline.task.run.duration')

        expect(attr[:value][:intValue]).to eq(120000)
      end
    end

    describe 'runner cicd.worker.* attributes' do
      it 'emits cicd.worker.id' do
        attr = find_attr(job_attrs, 'cicd.worker.id')

        expect(attr[:value][:stringValue]).to eq('1')
      end

      it 'emits cicd.worker.name' do
        attr = find_attr(job_attrs, 'cicd.worker.name')

        expect(attr[:value][:stringValue]).to eq('test-runner')
      end

      it 'emits cicd.worker.state as available when active is true' do
        pipeline_data[:builds].first[:runner][:active] = true
        attr = find_attr(job_attrs, 'cicd.worker.state')

        expect(attr[:value][:stringValue]).to eq('available')
      end

      it 'emits cicd.worker.state as offline when active is false' do
        pipeline_data[:builds].first[:runner][:active] = false
        attr = find_attr(job_attrs, 'cicd.worker.state')

        expect(attr[:value][:stringValue]).to eq('offline')
      end

      it 'emits gitlab.cicd.worker.tags' do
        attr = find_attr(job_attrs, 'gitlab.cicd.worker.tags')
        values = attr[:value][:arrayValue][:values].map { |v| v[:stringValue] }

        expect(values).to eq(%w[docker linux])
      end

      it 'emits gitlab.cicd.worker.type when runner_type present' do
        pipeline_data[:builds].first[:runner][:runner_type] = 'instance_type'
        attr = find_attr(job_attrs, 'gitlab.cicd.worker.type')

        expect(attr[:value][:stringValue]).to eq('instance_type')
      end

      it 'emits gitlab.cicd.runner.is_shared when is_shared present' do
        pipeline_data[:builds].first[:runner][:is_shared] = true
        attr = find_attr(job_attrs, 'gitlab.cicd.runner.is_shared')

        expect(attr[:value][:boolValue]).to be(true)
      end
    end

    describe 'vcs.* resource attributes' do
      it 'emits vcs.provider.name as gitlab' do
        attr = find_attr(resource_attrs, 'vcs.provider.name')

        expect(attr[:value][:stringValue]).to eq('gitlab')
      end

      it 'emits vcs.repository.name' do
        attr = find_attr(resource_attrs, 'vcs.repository.name')

        expect(attr[:value][:stringValue]).to eq('test-project')
      end

      it 'emits vcs.owner.name from path_with_namespace' do
        attr = find_attr(resource_attrs, 'vcs.owner.name')

        expect(attr[:value][:stringValue]).to eq('test-org')
      end

      it 'omits vcs.owner.name when namespace is empty' do
        pipeline_data[:project][:path_with_namespace] = 'top-level-project'
        attr = find_attr(resource_attrs, 'vcs.owner.name')

        expect(attr).to be_nil
      end

      it 'emits vcs.repository.url.full' do
        attr = find_attr(resource_attrs, 'vcs.repository.url.full')

        expect(attr[:value][:stringValue]).to eq('https://gitlab.com/test-org/test-project')
      end
    end

    describe 'merge request vcs attributes' do
      before do
        pipeline_data[:merge_request] = {
          id: 100,
          iid: 42,
          title: 'Add feature',
          state: 'opened',
          source_branch: 'feature-branch',
          target_branch: 'main'
        }
      end

      it 'emits vcs.change.id' do
        attr = find_attr(pipeline_attrs, 'vcs.change.id')

        expect(attr[:value][:stringValue]).to eq('100')
      end

      it 'emits vcs.change.title' do
        attr = find_attr(pipeline_attrs, 'vcs.change.title')

        expect(attr[:value][:stringValue]).to eq('Add feature')
      end

      it 'emits vcs.change.state mapped from opened to open' do
        attr = find_attr(pipeline_attrs, 'vcs.change.state')

        expect(attr[:value][:stringValue]).to eq('open')
      end

      it 'emits vcs.ref.base.name from target_branch' do
        attr = find_attr(pipeline_attrs, 'vcs.ref.base.name')

        expect(attr[:value][:stringValue]).to eq('main')
      end

      it 'maps merged state' do
        pipeline_data[:merge_request][:state] = 'merged'
        attr = find_attr(pipeline_attrs, 'vcs.change.state')

        expect(attr[:value][:stringValue]).to eq('merged')
      end
    end
  end
end
