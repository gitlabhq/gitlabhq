# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Observability::PipelineToTraces, feature_category: :observability do
  let(:integration) do
    Struct.new(:otel_endpoint_url, :otel_headers, :service_name, :environment).new(
      'https://example.com/otel',
      {},
      'gitlab-ci',
      'production'
    )
  end

  let(:pipeline_data) do
    {
      object_attributes: {
        id: 123,
        iid: 456,
        name: 'test-pipeline',
        ref: 'main',
        sha: 'abc123',
        status: 'success',
        detailed_status: 'passed',
        created_at: Time.zone.parse('2023-01-01T10:00:00Z'),
        finished_at: Time.zone.parse('2023-01-01T10:05:00Z'),
        duration: 300000,
        queued_duration: 30000,
        protected_ref: true,
        url: 'https://gitlab.com/project/-/pipelines/123'
      },
      project: {
        id: 789,
        name: 'test-project',
        path_with_namespace: 'group/test-project'
      },
      builds: [
        {
          id: 1,
          name: 'test-job',
          stage: 'test',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:01:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          duration: 120000,
          manual: false,
          allow_failure: false,
          runner: {
            id: 1,
            description: 'test-runner',
            tags: %w[docker linux]
          }
        }
      ]
    }
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
    spans.find { |span| span[:name].start_with?('job:') }
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
        { key: 'gitlab.project.id', value: { intValue: 789 } },
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } }
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

    it 'handles unhandled job status with STATUS_CODE_UNSET' do
      pipeline_data[:builds].first[:status] = 'pending'

      expect(job_span[:status][:code]).to eq('STATUS_CODE_UNSET')
    end

    it 'handles unhandled status with message' do
      pipeline_data[:object_attributes][:status] = 'skipped'
      pipeline_data[:object_attributes][:failure_reason] = 'manual_skip'

      aggregate_failures do
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_UNSET')
        expect(pipeline_span[:status][:message]).to eq('manual_skip')
      end
    end

    it 'does not include status message when failure_reason is absent' do
      pipeline_data[:object_attributes][:status] = 'success'

      aggregate_failures do
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_OK')
        expect(pipeline_span[:status]).not_to have_key(:message)
      end
    end

    it 'includes job attributes' do
      attributes = job_span[:attributes]

      expect(attributes).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.runner.description', value: { stringValue: 'test-runner' } }
      )
    end

    it 'handles empty pipeline data' do
      empty_data = {}
      converter = described_class.new(integration, empty_data)

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
      job_spans = spans.select { |span| span[:name].start_with?('job:') }

      aggregate_failures do
        expect(pipeline_span[:traceId]).to match(/\A[0-9a-f]{32}\z/)
        expect(pipeline_span[:traceId].length).to eq(32)
      end

      job_spans.each do |job_span|
        expect(job_span[:traceId]).to eq(pipeline_span[:traceId])
      end

      aggregate_failures do
        expect(pipeline_span[:spanId]).to match(/\A[0-9a-f]{16}\z/)
        expect(pipeline_span[:spanId].length).to eq(16)
        expect(pipeline_span[:parentSpanId]).to eq('')
      end

      job_spans.each do |job_span|
        aggregate_failures do
          expect(job_span[:spanId]).to match(/\A[0-9a-f]{16}\z/)
          expect(job_span[:spanId].length).to eq(16)
          expect(job_span[:parentSpanId]).to eq(pipeline_span[:spanId])
        end
      end

      all_span_ids = [pipeline_span[:spanId]] + job_spans.pluck(:spanId)
      expect(all_span_ids.uniq.length).to eq(all_span_ids.length)
    end

    context 'with optional pipeline attributes' do
      before do
        pipeline_data[:object_attributes][:tag] = true
        pipeline_data[:object_attributes][:before_sha] = 'def456'
        pipeline_data[:object_attributes][:stages] = %w[build test deploy]
        pipeline_data[:object_attributes][:iid] = 10
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
          { key: 'gitlab.cicd.pipeline.iid', value: { intValue: 10 } },
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
        attributes = job_span[:attributes]

        expect(attributes).to include(
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

    it 'does not include optional attributes when data is missing' do
      pipeline_attrs = pipeline_span[:attributes].pluck(:key)
      job_attrs = job_span[:attributes].pluck(:key)

      missing_pipeline_attrs = %w[
        pipeline.tag
        pipeline.before_sha
        pipeline.stages
        pipeline.user.id
        pipeline.commit.id
        pipeline.merge_request.id
        pipeline.source_pipeline.pipeline_id
        gitlab.cicd.pipeline.stages
      ]

      missing_job_attrs = %w[
        job.created_at
        job.when
        job.user.id
        job.artifacts.filename
        job.runner.type
        job.runner.is_shared
        gitlab.cicd.runner.is_shared
        job.environment.deployment_tier
      ]

      missing_pipeline_attrs.each do |attr|
        expect(pipeline_attrs).not_to include(attr)
      end

      missing_job_attrs.each do |attr|
        expect(job_attrs).not_to include(attr)
      end
    end
  end

  describe "OTel CI/CD semantic conventions (cicd.* and vcs.*)" do
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

    describe "pipeline cicd.* attributes" do
      it "emits cicd.pipeline.name" do
        attr = find_attr(pipeline_attrs, "cicd.pipeline.name")
        expect(attr[:value][:stringValue]).to eq("test-pipeline")
      end

      it "emits cicd.pipeline.run.id in resource" do
        attrs = resource[:attributes]
        attr = attrs.find { |a| a[:key] == "cicd.pipeline.run.id" }
        expect(attr[:value][:stringValue]).to eq("123")
      end

      it "emits cicd.pipeline.result with mapped value" do
        attr = find_attr(pipeline_attrs, "cicd.pipeline.result")
        expect(attr[:value][:stringValue]).to eq("success")
      end

      context "when pipeline status is failed" do
        before do
          pipeline_data[:object_attributes][:status] = "failed"
        end

        it "maps to failure" do
          attr = find_attr(pipeline_attrs, "cicd.pipeline.result")
          expect(attr[:value][:stringValue]).to eq("failure")
        end
      end

      context "when pipeline status is canceled" do
        before do
          pipeline_data[:object_attributes][:status] = "canceled"
        end

        it "maps to cancellation" do
          attr = find_attr(pipeline_attrs, "cicd.pipeline.result")
          expect(attr[:value][:stringValue]).to eq("cancellation")
        end
      end

      context "when pipeline status is running" do
        before do
          pipeline_data[:object_attributes][:status] = "running"
        end

        it "maps run.state to executing" do
          attr = find_attr(pipeline_attrs, "cicd.pipeline.run.state")
          expect(attr[:value][:stringValue]).to eq("executing")
        end
      end
    end

    describe "job cicd.pipeline.task.* attributes" do
      it "emits cicd.pipeline.task.name" do
        attr = find_attr(job_attrs, "cicd.pipeline.task.name")
        expect(attr[:value][:stringValue]).to eq("test-job")
      end

      it "emits cicd.pipeline.task.run.id" do
        attr = find_attr(job_attrs, "cicd.pipeline.task.run.id")
        expect(attr[:value][:stringValue]).to eq("1")
      end

      it "emits cicd.pipeline.task.run.result" do
        attr = find_attr(job_attrs, "cicd.pipeline.task.run.result")
        expect(attr[:value][:stringValue]).to eq("success")
      end

      it "emits cicd.pipeline.task.type from stage" do
        attr = find_attr(job_attrs, "cicd.pipeline.task.type")
        expect(attr[:value][:stringValue]).to eq("test")
      end
    end

    describe "runner cicd.worker.* attributes" do
      it "emits cicd.worker.id" do
        attr = find_attr(job_attrs, "cicd.worker.id")
        expect(attr[:value][:stringValue]).to eq("1")
      end

      it "emits cicd.worker.name" do
        attr = find_attr(job_attrs, "cicd.worker.name")
        expect(attr[:value][:stringValue]).to eq("test-runner")
      end

      it "emits cicd.worker.state as available when active is true" do
        pipeline_data[:builds].first[:runner][:active] = true
        attr = find_attr(job_attrs, "cicd.worker.state")
        expect(attr[:value][:stringValue]).to eq("available")
      end

      it "emits cicd.worker.state as offline when active is false" do
        pipeline_data[:builds].first[:runner][:active] = false
        attr = find_attr(job_attrs, "cicd.worker.state")
        expect(attr[:value][:stringValue]).to eq("offline")
      end

      it "emits cicd.worker.state as offline when active is nil" do
        pipeline_data[:builds].first[:runner][:active] = nil
        attr = find_attr(job_attrs, "cicd.worker.state")
        expect(attr[:value][:stringValue]).to eq("offline")
      end
    end

    describe "vcs.* resource attributes" do
      it "emits vcs.provider.name as gitlab" do
        attr = find_attr(resource_attrs, "vcs.provider.name")
        expect(attr[:value][:stringValue]).to eq("gitlab")
      end

      it "emits vcs.repository.name" do
        attr = find_attr(resource_attrs, "vcs.repository.name")
        expect(attr[:value][:stringValue]).to eq("test-project")
      end

      it "emits vcs.owner.name from path_with_namespace" do
        attr = find_attr(resource_attrs, "vcs.owner.name")
        expect(attr[:value][:stringValue]).to eq("group")
      end

      it "emits vcs.ref.head.name" do
        attr = find_attr(resource_attrs, "vcs.ref.head.name")
        expect(attr[:value][:stringValue]).to eq("main")
      end

      it "emits vcs.ref.head.revision" do
        attr = find_attr(resource_attrs, "vcs.ref.head.revision")
        expect(attr[:value][:stringValue]).to eq("abc123")
      end

      it "emits vcs.ref.head.type as branch" do
        attr = find_attr(resource_attrs, "vcs.ref.head.type")
        expect(attr[:value][:stringValue]).to eq("branch")
      end

      context "when pipeline is a tag" do
        before do
          pipeline_data[:object_attributes][:tag] = true
        end

        it "emits vcs.ref.head.type as tag" do
          attr = find_attr(resource_attrs, "vcs.ref.head.type")
          expect(attr[:value][:stringValue]).to eq("tag")
        end
      end

      context "when path_with_namespace has no namespace" do
        before do
          pipeline_data[:project][:path_with_namespace] = "top-level-project"
        end

        it "omits vcs.owner.name when namespace is empty" do
          attr = find_attr(resource_attrs, "vcs.owner.name")
          expect(attr).to be_nil
        end
      end

      describe "conditional attribute emission" do
        it "omits cicd.pipeline.result when status is running" do
          pipeline_data[:object_attributes][:status] = "running"
          keys = pipeline_span[:attributes].map { |a| a[:key] }
          expect(keys).not_to include("cicd.pipeline.result")
        end

        it "omits cicd.pipeline.run.state when status is terminal" do
          keys = pipeline_span[:attributes].map { |a| a[:key] }
          expect(keys).not_to include("cicd.pipeline.run.state")
        end

        it "omits cicd.pipeline.trigger.type when source is nil" do
          pipeline_data[:object_attributes][:source] = nil
          keys = pipeline_span[:attributes].map { |a| a[:key] }
          expect(keys).not_to include("cicd.pipeline.trigger.type")
        end

        it "emits cicd.pipeline.trigger.type when source is push" do
          pipeline_data[:object_attributes][:source] = "push"
          attr = find_attr(pipeline_attrs, "cicd.pipeline.trigger.type")
          expect(attr[:value][:stringValue]).to eq("push")
        end

        it "omits cicd.pipeline.task.type for unknown stages" do
          pipeline_data[:builds].first[:stage] = "lint"
          keys = job_span[:attributes].map { |a| a[:key] }
          expect(keys).not_to include("cicd.pipeline.task.type")
        end

        it "emits vcs.ref.base.revision when before_sha is present" do
          pipeline_data[:object_attributes][:before_sha] = "def456"
          attr = find_attr(pipeline_attrs, "vcs.ref.base.revision")
          expect(attr[:value][:stringValue]).to eq("def456")
        end

        it "emits vcs.repository.url.full in resource" do
          pipeline_data[:project][:web_url] = "https://gitlab.com/group/project"
          attr = find_attr(resource_attrs, "vcs.repository.url.full")
          expect(attr[:value][:stringValue]).to eq("https://gitlab.com/group/project")
        end
      end

      describe "new semconv attributes from #96" do
        describe "pipeline semconv" do
          it "emits cicd.pipeline.run.queue_duration" do
            attr = find_attr(pipeline_attrs, "cicd.pipeline.run.queue_duration")
            expect(attr[:value][:intValue]).to eq(30000)
          end

          it "emits vcs.ref.head.protected" do
            attr = find_attr(pipeline_attrs, "vcs.ref.head.protected")
            expect(attr[:value][:boolValue]).to be(true)
          end

          it "emits gitlab.cicd.pipeline.iid" do
            attr = find_attr(pipeline_attrs, "gitlab.cicd.pipeline.iid")
            expect(attr[:value][:intValue]).to eq(456)
          end

          it "emits gitlab.cicd.pipeline.stages when stages present" do
            pipeline_data[:object_attributes][:stages] = %w[build test deploy]
            attr = find_attr(pipeline_attrs, "gitlab.cicd.pipeline.stages")
            values = attr[:value][:arrayValue][:values].map { |v| v[:stringValue] }
            expect(values).to eq(%w[build test deploy])
          end
        end

        describe "vcs ref attributes" do
          it "emits vcs.ref.head.name in pipeline span" do
            attr = find_attr(pipeline_attrs, "vcs.ref.head.name")
            expect(attr[:value][:stringValue]).to eq("main")
          end

          it "emits vcs.ref.head.revision in pipeline span" do
            attr = find_attr(pipeline_attrs, "vcs.ref.head.revision")
            expect(attr[:value][:stringValue]).to eq("abc123")
          end

          it "emits vcs.ref.base.revision when before_sha present" do
            pipeline_data[:object_attributes][:before_sha] = "def456"
            attr = find_attr(pipeline_attrs, "vcs.ref.base.revision")
            expect(attr[:value][:stringValue]).to eq("def456")
          end
        end

        describe "job semconv" do
          it "emits cicd.pipeline.task.allow_failure" do
            attr = find_attr(job_attrs, "cicd.pipeline.task.allow_failure")
            expect(attr[:value][:boolValue]).to be(false)
          end

          it "emits cicd.pipeline.task.run.failure_reason" do
            pipeline_data[:builds].first[:failure_reason] = "script_failure"
            attr = find_attr(job_attrs, "cicd.pipeline.task.run.failure_reason")
            expect(attr[:value][:stringValue]).to eq("script_failure")
          end

          it "emits cicd.pipeline.task.trigger.type as automatic for non-manual jobs" do
            attr = find_attr(job_attrs, "cicd.pipeline.task.trigger.type")
            expect(attr[:value][:stringValue]).to eq("automatic")
          end

          it "emits cicd.pipeline.task.trigger.type as manual for manual jobs" do
            pipeline_data[:builds].first[:manual] = true
            attr = find_attr(job_attrs, "cicd.pipeline.task.trigger.type")
            expect(attr[:value][:stringValue]).to eq("manual")
          end

          it "emits cicd.pipeline.task.run.queue_duration" do
            pipeline_data[:builds].first[:queued_duration] = 5000
            attr = find_attr(job_attrs, "cicd.pipeline.task.run.queue_duration")
            expect(attr[:value][:intValue]).to eq(5000)
          end

          it "emits cicd.pipeline.task.run.state" do
            attr = find_attr(job_attrs, "cicd.pipeline.task.run.state")
            expect(attr).to be_nil
          end

          it "emits cicd.pipeline.task.run.state as executing when running" do
            pipeline_data[:builds].first[:status] = "running"
            attr = find_attr(job_attrs, "cicd.pipeline.task.run.state")
            expect(attr[:value][:stringValue]).to eq("executing")
          end
        end

        describe "runner semconv" do
          it "emits cicd.worker.tags" do
            attr = find_attr(job_attrs, "cicd.worker.tags")
            values = attr[:value][:arrayValue][:values].map { |v| v[:stringValue] }
            expect(values).to eq(%w[docker linux])
          end

          it "emits cicd.worker.type when runner_type present" do
            pipeline_data[:builds].first[:runner][:runner_type] = "instance_type"
            attr = find_attr(job_attrs, "cicd.worker.type")
            expect(attr[:value][:stringValue]).to eq("instance_type")
          end

          it "emits gitlab.cicd.worker.is_shared when is_shared present" do
            pipeline_data[:builds].first[:runner][:is_shared] = true
            attr = find_attr(job_attrs, "gitlab.cicd.runner.is_shared")
            expect(attr[:value][:boolValue]).to be(true)
          end
        end

        describe "merge request vcs attributes" do
          before do
            pipeline_data[:merge_request] = {
              id: 100,
              iid: 42,
              title: "Add feature",
              state: "opened",
              source_branch: "feature-branch",
              target_branch: "main"
            }
          end

          it "emits vcs.change.id" do
            attr = find_attr(pipeline_attrs, "vcs.change.id")
            expect(attr[:value][:stringValue]).to eq("42")
          end

          it "emits vcs.change.title" do
            attr = find_attr(pipeline_attrs, "vcs.change.title")
            expect(attr[:value][:stringValue]).to eq("Add feature")
          end

          it "emits vcs.change.state mapped from opened to open" do
            attr = find_attr(pipeline_attrs, "vcs.change.state")
            expect(attr[:value][:stringValue]).to eq("open")
          end

          it "emits vcs.ref.head.name from source_branch" do
            attr = pipeline_span[:attributes].reverse.find { |a| a[:key] == "vcs.ref.head.name" }
            expect(attr[:value][:stringValue]).to eq("feature-branch")
          end

          it "emits vcs.ref.base.name from target_branch" do
            attr = find_attr(pipeline_attrs, "vcs.ref.base.name")
            expect(attr[:value][:stringValue]).to eq("main")
          end

          it "maps merged state" do
            pipeline_data[:merge_request][:state] = "merged"
            attr = find_attr(pipeline_attrs, "vcs.change.state")
            expect(attr[:value][:stringValue]).to eq("merged")
          end
        end
      end
    end
  end
end
