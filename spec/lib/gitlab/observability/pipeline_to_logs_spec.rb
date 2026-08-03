# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/gitlab/ci/trace_context'
require_relative '../../../support/shared_contexts/lib/gitlab/observability/pipeline_converter_shared_context'

RSpec.describe Gitlab::Observability::PipelineToLogs, feature_category: :observability do
  include_context 'with pipeline converter data'

  let(:pipeline_data) { base_pipeline_data }
  let(:converter) { described_class.new(integration, pipeline_data) }

  describe '#convert' do
    it 'returns valid OTEL logs format' do
      result = converter.convert

      aggregate_failures do
        expect(result).to have_key(:resourceLogs)
        expect(result[:resourceLogs]).to be_an(Array)
        expect(result[:resourceLogs].length).to eq(1)
      end
    end

    it 'includes resource attributes' do
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
        { key: 'vcs.repository.name', value: { stringValue: 'test-project' } },
        { key: 'vcs.owner.name', value: { stringValue: 'test-org' } }
      )
    end

    it 'does not include pipeline run attributes in resource' do
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]
      resource_keys = resource[:attributes].map { |a| a[:key] }

      expect(resource_keys).not_to include('cicd.pipeline.run.id')
      expect(resource_keys).not_to include('cicd.pipeline.name')
    end

    it 'includes pipeline log record' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      aggregate_failures do
        expect(pipeline_log).to be_present
        expect(pipeline_log[:body][:stringValue]).to include('Pipeline success: test-pipeline')
        expect(pipeline_log[:severityText]).to eq('INFO')
      end
    end

    it 'includes job log records' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_logs = log_records.select do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
      end

      expect(job_logs.length).to eq(2)

      success_job_log = job_logs.find { |log| log[:body][:stringValue].include?('test-job') }
      expect(success_job_log[:severityText]).to eq('INFO')

      failed_job_log = job_logs.find { |log| log[:body][:stringValue].include?('failed-job') }
      expect(failed_job_log[:severityText]).to eq('ERROR')
    end

    it 'sets correct severity levels' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      aggregate_failures do
        expect(pipeline_log[:severityNumber]).to eq(9)
        expect(pipeline_log[:severityText]).to eq('INFO')
      end

      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }

      aggregate_failures do
        expect(failed_job_log[:severityNumber]).to eq(17)
        expect(failed_job_log[:severityText]).to eq('ERROR')
      end
    end

    it 'includes pipeline legacy attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      expect(pipeline_log[:attributes]).to include(
        { key: 'pipeline.id', value: { intValue: 123 } },
        { key: 'pipeline.name', value: { stringValue: 'test-pipeline' } },
        { key: 'pipeline.status', value: { stringValue: 'success' } },
        { key: 'pipeline.duration', value: { intValue: 300000 } }
      )
    end

    it 'includes job legacy attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }

      expect(job_log[:attributes]).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.status', value: { stringValue: 'success' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.artifacts.filename', value: { stringValue: 'test-results.xml' } }
      )
    end

    it 'handles empty pipeline data' do
      converter = described_class.new(integration, {})
      result = converter.convert

      expect(result[:resourceLogs]).to be_empty
    end

    it 'handles missing timestamps gracefully' do
      pipeline_data[:object_attributes].delete(:finished_at)
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      expect(pipeline_log[:timeUnixNano]).to be > 0
    end

    it 'handles invalid timestamps gracefully' do
      pipeline_data[:object_attributes][:finished_at] = 'not-a-timestamp'
      pipeline_data[:object_attributes][:created_at] = 'also-invalid'
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      expect(pipeline_log[:timeUnixNano]).to eq(0)
    end

    it 'includes failure reason for failed jobs' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }

      expect(failed_job_log[:attributes]).to include(
        { key: 'job.failure_reason', value: { stringValue: 'script_failure' } }
      )
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end

    it 'handles different pipeline statuses' do
      pipeline_data[:object_attributes][:status] = 'canceled'
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
      end

      expect(pipeline_log[:severityText]).to eq('WARN')
    end

    context 'with trace context correlation' do
      it 'includes traceId on pipeline log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        pipeline_log = log_records.find do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
        end

        expect(pipeline_log[:traceId]).to eq(expected_trace_id)
      end

      it 'includes spanId on pipeline log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        pipeline_log = log_records.find do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
        end

        expect(pipeline_log[:spanId]).to eq(expected_pipeline_span_id)
      end

      it 'includes flags: 1 on pipeline log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        pipeline_log = log_records.find do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
        end

        expect(pipeline_log[:flags]).to eq(1)
      end

      it 'includes traceId on job log records' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        job_logs = log_records.select do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
        end

        job_logs.each do |job_log|
          expect(job_log[:traceId]).to eq(expected_trace_id)
        end
      end

      it 'includes distinct spanId per job log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        job_logs = log_records.select do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
        end

        span_ids = job_logs.map { |log| log[:spanId] }

        aggregate_failures do
          expect(span_ids.uniq.size).to eq(2)
          expect(span_ids.first).to eq(Gitlab::Ci::TraceContext.span_id_for_job(root_pipeline_id, 1, :export))
          expect(span_ids.last).to eq(Gitlab::Ci::TraceContext.span_id_for_job(root_pipeline_id, 2, :export))
        end
      end

      it 'includes flags: 1 on job log records' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        job_logs = log_records.select do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
        end

        job_logs.each do |job_log|
          expect(job_log[:flags]).to eq(1)
        end
      end

      context 'with root_pipeline_id in pipeline data' do
        before do
          pipeline_data[:object_attributes][:root_pipeline_id] = 999
        end

        it 'uses root_pipeline_id for trace correlation' do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

          pipeline_log = log_records.find do |log|
            log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
          end

          expect(pipeline_log[:traceId]).to eq(Gitlab::Ci::TraceContext.trace_id_for(999))
        end
      end

      it 'produces trace IDs matching PipelineToTraces for the same pipeline' do
        logs_result = converter.convert
        traces_converter = Gitlab::Observability::PipelineToTraces.new(integration, pipeline_data)
        traces_result = traces_converter.convert

        log_trace_id = logs_result[:resourceLogs].first[:scopeLogs].first[:logRecords].first[:traceId]
        span_trace_id = traces_result[:resourceSpans].first[:scopeSpans].first[:spans].first[:traceId]

        expect(log_trace_id).to eq(span_trace_id)
      end
    end

    context 'with OTel Semantic Convention attributes' do
      describe 'pipeline log semconv attributes' do
        let(:pipeline_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find do |log|
            log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
          end
        end

        it 'includes cicd.pipeline.name' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } }
          )
        end

        it 'omits cicd.pipeline.name when pipeline name is blank' do
          pipeline_data[:object_attributes][:name] = nil
          keys = pipeline_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('cicd.pipeline.name')
        end

        it 'includes cicd.pipeline.run.id' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.run.id', value: { stringValue: '123' } }
          )
        end

        it 'includes cicd.pipeline.run.url.full' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.run.url.full',
              value: { stringValue: 'https://gitlab.com/project/-/pipelines/123' } }
          )
        end

        it 'omits cicd.pipeline.run.url.full when url is blank' do
          pipeline_data[:object_attributes][:url] = nil
          keys = pipeline_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('cicd.pipeline.run.url.full')
        end

        it 'includes vcs.ref.head.name' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.name', value: { stringValue: 'main' } }
          )
        end

        it 'includes vcs.ref.head.revision' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.revision', value: { stringValue: 'abc123' } }
          )
        end

        it 'includes vcs.ref.head.type as branch' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
          )
        end

        it 'includes vcs.ref.head.type as tag when pipeline is a tag' do
          pipeline_data[:object_attributes][:tag] = true

          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.type', value: { stringValue: 'tag' } }
          )
        end

        it 'includes gitlab.cicd.pipeline.run.duration' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.run.duration', value: { intValue: 300000 } }
          )
        end

        it 'includes gitlab.cicd.pipeline.run.queued_duration' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.run.queued_duration', value: { intValue: 30000 } }
          )
        end

        it 'includes gitlab.cicd.pipeline.trigger.type with raw source value' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } }
          )
        end

        it 'omits gitlab.cicd.pipeline.trigger.type when source is nil' do
          pipeline_data[:object_attributes][:source] = nil
          keys = pipeline_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('gitlab.cicd.pipeline.trigger.type')
        end

        it 'includes gitlab.vcs.ref.head.protected' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'gitlab.vcs.ref.head.protected', value: { boolValue: true } }
          )
        end

        it 'sets gitlab.vcs.ref.head.protected to false when ref is not protected' do
          pipeline_data[:object_attributes][:protected_ref] = false

          expect(pipeline_log[:attributes]).to include(
            { key: 'gitlab.vcs.ref.head.protected', value: { boolValue: false } }
          )
        end

        context 'for cicd.pipeline.result via CicdSemconv' do
          it 'maps success to success' do
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
            )
          end

          it 'maps failed to failure' do
            pipeline_data[:object_attributes][:status] = 'failed'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'failure' } }
            )
          end

          it 'maps canceled to cancellation' do
            pipeline_data[:object_attributes][:status] = 'canceled'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'cancellation' } }
            )
          end

          it 'maps skipped to skip' do
            pipeline_data[:object_attributes][:status] = 'skipped'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'skip' } }
            )
          end

          it 'omits cicd.pipeline.result when status has no mapped result' do
            pipeline_data[:object_attributes][:status] = 'running'
            keys = pipeline_log[:attributes].map { |a| a[:key] }

            expect(keys).not_to include('cicd.pipeline.result')
          end
        end

        context 'for cicd.pipeline.run.state via CicdSemconv' do
          it 'maps running to executing' do
            pipeline_data[:object_attributes][:status] = 'running'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'executing' } }
            )
          end

          it 'maps pending to pending' do
            pipeline_data[:object_attributes][:status] = 'pending'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'maps waiting_for_resource to pending' do
            pipeline_data[:object_attributes][:status] = 'waiting_for_resource'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'maps preparing to pending' do
            pipeline_data[:object_attributes][:status] = 'preparing'

            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'omits cicd.pipeline.run.state when status has no mapped state' do
            pipeline_data[:object_attributes][:status] = 'success'
            keys = pipeline_log[:attributes].map { |a| a[:key] }

            expect(keys).not_to include('cicd.pipeline.run.state')
          end
        end
      end

      describe 'job log semconv attributes' do
        let(:job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        end

        let(:failed_job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
        end

        it 'includes cicd.pipeline.task.name' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.name', value: { stringValue: 'test-job' } }
          )
        end

        it 'includes cicd.pipeline.task.run.id as string' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.id', value: { stringValue: '1' } }
          )
        end

        it 'includes cicd.pipeline.task.run.url.full' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.url.full',
              value: { stringValue: 'https://gitlab.com/test-org/test-project/-/jobs/1' } }
          )
        end

        it 'includes cicd.pipeline.task.type from stage' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.type', value: { stringValue: 'test' } }
          )
        end

        it 'includes cicd.pipeline.task.type with raw stage value' do
          pipeline_data[:builds].first[:stage] = 'deploy'
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          deploy_job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }

          expect(deploy_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.type', value: { stringValue: 'deploy' } }
          )
        end

        it 'includes cicd.pipeline.task.run.result for terminal statuses' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.result', value: { stringValue: 'success' } }
          )
          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.result', value: { stringValue: 'failure' } }
          )
        end

        it 'omits cicd.pipeline.task.run.result when status has no mapped result' do
          pipeline_data[:builds].first[:status] = 'running'
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          running_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
          keys = running_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('cicd.pipeline.task.run.result')
        end

        it 'omits cicd.pipeline.task.run.state when status has no mapped state' do
          keys = job_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('cicd.pipeline.task.run.state')
        end

        it 'includes cicd.pipeline.task.run.state for in-progress statuses' do
          pipeline_data[:builds].first[:status] = 'running'
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          running_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }

          expect(running_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.state', value: { stringValue: 'executing' } }
          )
        end

        it 'includes gitlab.cicd.pipeline.task.allow_failure' do
          expect(job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.allow_failure', value: { boolValue: false } }
          )
          expect(failed_job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.allow_failure', value: { boolValue: true } }
          )
        end

        it 'includes gitlab.cicd.pipeline.task.run.failure_reason when present' do
          expect(failed_job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.run.failure_reason', value: { stringValue: 'script_failure' } }
          )
        end

        it 'omits gitlab.cicd.pipeline.task.run.failure_reason when not present' do
          keys = job_log[:attributes].map { |a| a[:key] }

          expect(keys).not_to include('gitlab.cicd.pipeline.task.run.failure_reason')
        end

        it 'includes gitlab.cicd.pipeline.task.trigger.type with raw source value' do
          expect(job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.trigger.type', value: { stringValue: 'push' } }
          )
        end

        it 'includes gitlab.cicd.pipeline.task.trigger.type with raw source for manual jobs' do
          expect(failed_job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.trigger.type', value: { stringValue: 'push' } }
          )
        end

        it 'includes gitlab.cicd.pipeline.task.run.queued_duration' do
          expect(job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.run.queued_duration', value: { intValue: 5000 } }
          )
          expect(failed_job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.run.queued_duration', value: { intValue: 2000 } }
          )
        end

        it 'includes gitlab.cicd.pipeline.task.run.duration' do
          expect(job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.run.duration', value: { intValue: 120000 } }
          )
          expect(failed_job_log[:attributes]).to include(
            { key: 'gitlab.cicd.pipeline.task.run.duration', value: { intValue: 60000 } }
          )
        end
      end

      describe 'runner/worker semconv attributes' do
        let(:job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        end

        it 'includes cicd.worker.id as string' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.worker.id', value: { stringValue: '1' } }
          )
        end

        it 'includes gitlab.cicd.worker.tags' do
          expect(job_log[:attributes]).to include(
            { key: 'gitlab.cicd.worker.tags', value: { arrayValue: { values: [
              { stringValue: 'docker' },
              { stringValue: 'linux' }
            ] } } }
          )
        end

        it 'does not include worker attributes when runner is absent' do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }

          worker_attrs = failed_job_log[:attributes].select do |attr|
            attr[:key].start_with?('cicd.worker.', 'gitlab.cicd.worker.')
          end

          expect(worker_attrs).to be_empty
        end
      end
    end

    it 'includes environment attributes correctly' do
      pipeline_data[:builds].first[:environment] = { name: 'production', action: 'start' }
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
      job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }

      expect(job_log[:attributes]).to include(
        { key: 'job.environment.name', value: { stringValue: 'production' } },
        { key: 'job.environment.action', value: { stringValue: 'start' } }
      )
    end

    context 'with bridge jobs' do
      before do
        pipeline_data[:bridges] = [{
          id: 3,
          name: 'trigger-child',
          stage: 'trigger',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:04:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:04:30Z'),
          duration: 30000,
          queued_duration: 1000,
          manual: false,
          allow_failure: false,
          bridge: true
        }]
      end

      it 'emits bridge jobs as log records' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        bridge_log = log_records.find { |log| log[:body][:stringValue].include?('trigger-child') }

        aggregate_failures do
          expect(bridge_log).to be_present
          expect(bridge_log[:body][:stringValue]).to eq('Job success: trigger-child (trigger)')
          expect(bridge_log[:severityText]).to eq('INFO')
        end
      end

      it 'marks bridge job log with job.type attribute' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        bridge_log = log_records.find { |log| log[:body][:stringValue].include?('trigger-child') }

        expect(bridge_log[:attributes]).to include(
          { key: 'job.type', value: { stringValue: 'bridge' } }
        )
      end
    end
  end

  describe '#map_severity' do
    it 'maps status to severity number correctly' do
      test_cases = {
        'success' => 9,
        'failed' => 17,
        'canceled' => 13,
        'running' => 5,
        'pending' => 5,
        nil => 5
      }

      aggregate_failures do
        test_cases.each do |status, expected|
          expect(converter.send(:map_severity, status)).to eq(expected),
            "Expected #{status.inspect} to map to #{expected}"
        end
      end
    end
  end

  describe '#map_severity_text' do
    it 'maps status to severity text correctly' do
      test_cases = {
        'success' => 'INFO',
        'failed' => 'ERROR',
        'canceled' => 'WARN',
        'running' => 'DEBUG',
        'pending' => 'DEBUG',
        nil => 'DEBUG'
      }

      aggregate_failures do
        test_cases.each do |status, expected|
          expect(converter.send(:map_severity_text, status)).to eq(expected),
            "Expected #{status.inspect} to map to #{expected}"
        end
      end
    end
  end

  describe '#time_to_nanoseconds' do
    it 'returns 0 for blank values' do
      aggregate_failures do
        expect(converter.send(:time_to_nanoseconds, nil)).to eq(0)
        expect(converter.send(:time_to_nanoseconds, '')).to eq(0)
      end
    end

    it 'converts ActiveSupport::TimeWithZone to nanoseconds' do
      time = ActiveSupport::TimeZone['UTC'].parse('2023-01-01T10:00:00Z')
      expected = (time.to_f * 1_000_000_000).to_i

      expect(converter.send(:time_to_nanoseconds, time)).to eq(expected)
    end

    it 'returns 0 for non-TimeWithZone objects' do
      expect(converter.send(:time_to_nanoseconds, Time.parse('2023-01-01T10:00:00Z'))).to eq(0)
    end
  end
end
