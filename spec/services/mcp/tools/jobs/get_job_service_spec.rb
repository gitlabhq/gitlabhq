# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Jobs::GetJobService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: [user]) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'class configuration' do
    it 'registers version 0.1.0 as read-only' do
      expect(described_class.available_versions).to include('0.1.0')
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end

    it 'aliases the old get_job_log tool name' do
      expect(described_class.tool_aliases).to eq(['get_job_log'])
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          id: {
            type: 'string',
            description: 'ID or full path of the project'
          },
          job_id: {
            type: 'integer',
            description: 'ID of the job'
          },
          include: {
            type: 'array',
            description: 'Facet to include alongside the job, one per call: log.',
            items: {
              type: 'string',
              enum: %w[log]
            },
            maxItems: 1
          },
          byte_offset: {
            type: 'integer',
            minimum: 0,
            description: "Byte offset to start reading the job's log from. Only applies when include is log. " \
              'Default is 0.'
          },
          byte_limit: {
            type: 'integer',
            minimum: 1,
            maximum: 500.kilobytes,
            description: "Maximum number of bytes of the job's log to return. Only applies when include is " \
              "log. Default and max is #{500.kilobytes}."
          }
        },
        required: %w[id job_id]
      })
    end
  end

  describe '#execute' do
    let_it_be(:job) { create(:ci_build, :failed, pipeline: pipeline, name: 'rspec') }

    let(:current_user) { user }

    # A fresh instance per call, because the service memoizes the job it authorized.
    def execute(arguments, name: 'get_job')
      service = described_class.new(name: 'get_job', version: '0.1.0')
      service.set_cred(current_user: current_user)
      service.execute(params: { name: name, arguments: arguments })
    end

    it 'returns the job metadata without the log facet', :aggregate_failures do
      result = execute({ id: project.full_path, job_id: job.id })

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to eq({
        id: job.id,
        name: 'rspec',
        status: 'failed',
        stage: job.stage,
        allow_failure: job.allow_failure,
        web_url: Gitlab::Routing.url_helpers.project_job_url(project, job)
      })
    end

    context 'when the job does not exist' do
      it 'returns an error that does not distinguish missing from inaccessible' do
        result = execute({ id: project.full_path, job_id: non_existing_record_id })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include(
          'Job not found: it does not exist or you do not have access to it.'
        )
      end
    end

    context 'when the project does not exist' do
      it 'returns an error' do
        result = execute({ id: 'does-not/exist', job_id: job.id })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to match(/not found or inaccessible/)
      end
    end

    context 'when the user cannot read the project' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_job) { create(:ci_build, pipeline: create(:ci_pipeline, project: private_project)) }

      let(:current_user) { create(:user) }

      # Otherwise the distinct "Job not found" message would confirm the project exists.
      it 'returns the same error as a project that does not exist' do
        result = execute({ id: private_project.full_path, job_id: private_job.id })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include(
          "Project '#{private_project.full_path}' not found or inaccessible"
        )
      end
    end

    context 'when the user cannot read the job' do
      let_it_be(:hidden_project) { create(:project, :public, public_builds: false) }
      let_it_be(:hidden_job) { create(:ci_build, pipeline: create(:ci_pipeline, project: hidden_project)) }

      let(:current_user) { create(:user) }

      # The log path must not confirm the job either, or it becomes a way to probe for jobs.
      it 'hides whether the job exists on both paths', :aggregate_failures do
        [{}, { include: %w[log] }].each do |extra|
          result = execute({ id: hidden_project.full_path, job_id: hidden_job.id }.merge(extra))

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include(
            'Job not found: it does not exist or you do not have access to it.'
          )
        end
      end
    end

    context 'when current_user is not set' do
      let(:current_user) { nil }

      it 'returns an error' do
        result = execute({ id: project.full_path, job_id: job.id })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end

    context 'with the log facet' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'returns the whole trace when it fits in one window', :aggregate_failures do
        result = execute({ id: project.full_path, job_id: job.id, include: %w[log] })

        log = result[:structuredContent][:log]
        expect(log[:content]).to eq('BUILD TRACE')
        expect(log[:metadata]).to eq({ total_bytes: 11, returned: { start: 0, end: 11 }, truncated: false })
        expect(log).not_to have_key(:system_instruction)
      end

      context 'when the requested window does not reach the end of the trace' do
        it 'truncates and points at the next byte_offset', :aggregate_failures do
          result = execute({ id: project.full_path, job_id: job.id, include: %w[log], byte_limit: 5 })

          log = result[:structuredContent][:log]
          expect(log[:content]).to eq('BUILD')
          expect(log[:metadata]).to eq({ total_bytes: 11, returned: { start: 0, end: 5 }, truncated: true })
          expect(log[:system_instruction]).to eq(
            'Log truncated. Remaining: 6 bytes. Call again with {"byte_offset": 5}.'
          )
        end
      end

      context 'when byte_limit is above the maximum' do
        it 'returns a validation error' do
          result = execute({ id: project.full_path, job_id: job.id, include: %w[log], byte_limit: 500.kilobytes + 1 })

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('byte_limit is invalid')
        end
      end

      context 'when byte_offset is past the end of the trace' do
        it 'reports an empty window at the end of the trace' do
          result = execute({ id: project.full_path, job_id: job.id, include: %w[log], byte_offset: 100 })

          expect(result[:structuredContent][:log][:metadata]).to eq(
            { total_bytes: 11, returned: { start: 11, end: 11 }, truncated: false }
          )
        end
      end

      context 'when a byte window splits a multi-byte character' do
        let(:utf8_job) { create(:ci_build, pipeline: pipeline) }

        before do
          utf8_job.trace.set('✓ done')
        end

        it 'replaces the partial character so the response can be serialized', :aggregate_failures do
          result = execute({ id: project.full_path, job_id: utf8_job.id, include: %w[log], byte_limit: 2 })

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent][:log][:content]).to eq('�')
        end
      end

      context 'when the job ran in debug mode' do
        let(:debug_job) do
          create(:ci_build, :trace_live, pipeline: pipeline,
            yaml_variables: [{ key: 'CI_DEBUG_TRACE', value: 'true' }])
        end

        # Reading a debug trace needs write access, so a public-build reader gets the metadata only.
        let(:current_user) { create(:user) }

        it 'returns the metadata but refuses the log', :aggregate_failures do
          expect(execute({ id: project.full_path, job_id: debug_job.id })[:isError]).to be(false)

          result = execute({ id: project.full_path, job_id: debug_job.id, include: %w[log] })

          expect(result[:isError]).to be(true)
          # The caller can already see this job, so the refusal names the reason instead of
          # claiming the job does not exist.
          expect(result[:content].first[:text]).to include(
            "Job log not accessible: you do not have permission to read this job's log."
          )
        end
      end
    end

    context 'when called as the get_job_log alias' do
      let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

      it 'returns the log without an explicit include' do
        result = execute({ id: project.full_path, job_id: job.id }, name: 'get_job_log')

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:log][:content]).to eq('BUILD TRACE')
      end
    end
  end
end
