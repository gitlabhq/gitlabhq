# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Pipelines::GetPipelineTool, :request_store, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, maintainers: [user]) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', status: :success, source: :push) }

  let(:params) { { id: project.full_path, pipeline_id: pipeline.id } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('project')
    end
  end

  describe '#build_variables' do
    it 'resolves the project full path and pipeline global id', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:pipelineId]).to eq("gid://gitlab/Ci::Pipeline/#{pipeline.id}")
    end

    it 'defaults every include facet to false when include is omitted', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:includeJobs]).to be(false)
      expect(variables[:includeDownstreamPipelines]).to be(false)
      expect(variables[:includeBridgeJobs]).to be(false)
    end

    it 'defaults first to 20 and omits after' do
      variables = tool.build_variables

      expect(variables[:first]).to eq(20)
      expect(variables).not_to have_key(:after)
    end

    context 'when a single facet is requested' do
      using RSpec::Parameterized::TableSyntax

      where(:facet, :enabled_key) do
        'jobs'                  | :includeJobs
        'downstream_pipelines'  | :includeDownstreamPipelines
        'bridge_jobs'           | :includeBridgeJobs
      end

      with_them do
        let(:params) { super().merge(include: [facet]) }

        it 'enables only the requested facet', :aggregate_failures do
          variables = tool.build_variables
          all_keys = %i[includeJobs includeDownstreamPipelines includeBridgeJobs]

          expect(variables[enabled_key]).to be(true)
          (all_keys - [enabled_key]).each { |key| expect(variables[key]).to be(false) }
        end
      end
    end

    context 'when job_status is provided' do
      let(:params) { super().merge(include: ['jobs'], job_status: 'failed') }

      it 'upcases it into the jobStatuses GraphQL enum variable' do
        variables = tool.build_variables

        expect(variables[:jobStatuses]).to eq(['FAILED'])
      end
    end

    context 'when first and after are provided' do
      let(:params) { super().merge(include: ['jobs'], first: 5, after: 'cursor1') }

      it 'passes them through', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:first]).to eq(5)
        expect(variables[:after]).to eq('cursor1')
      end
    end
  end

  describe 'integration' do
    it 'returns the base pipeline without any facets by default', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to eq({
        id: pipeline.id,
        status: 'success',
        ref: 'master',
        sha: pipeline.sha,
        source: 'push',
        web_url: Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "/#{project.full_path}/-/pipelines/#{pipeline.id}")
      })
    end

    context 'with include: jobs' do
      let_it_be(:failed_build) { create(:ci_build, :failed, pipeline: pipeline, name: 'rspec') }
      let_it_be(:success_build) { create(:ci_build, :success, pipeline: pipeline, name: 'build') }
      let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline, status: :success, name: 'trigger') }

      let(:params) { super().merge(include: ['jobs']) }

      it 'returns only real jobs, excluding bridges', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        job_ids = result[:structuredContent][:jobs].pluck(:id)
        expect(job_ids).to contain_exactly(failed_build.id, success_build.id)
        expect(result[:structuredContent][:jobs]).to include(
          hash_including(
            id: failed_build.id,
            name: 'rspec',
            status: 'failed',
            allow_failure: false,
            web_url: Gitlab::Utils.append_path(
              Gitlab.config.gitlab.url, "/#{project.full_path}/-/jobs/#{failed_build.id}"
            )
          )
        )
        expect(result[:structuredContent][:jobs].first.keys).to contain_exactly(
          :id, :name, :status, :stage, :allow_failure, :web_url
        )
      end

      context 'with job_status filter' do
        let(:params) { super().merge(job_status: 'failed') }

        it 'returns only jobs matching the status' do
          result = tool.execute

          job_ids = result[:structuredContent][:jobs].pluck(:id)
          expect(job_ids).to contain_exactly(failed_build.id)
        end
      end

      context 'with pagination' do
        let(:params) { super().merge(first: 1) }

        it 'limits the number of jobs returned and reports another page is available', :aggregate_failures do
          result = tool.execute

          expect(result[:structuredContent][:jobs].size).to eq(1)
          expect(result[:structuredContent][:page_info][:has_next_page]).to be(true)
          expect(result[:structuredContent][:page_info][:end_cursor]).to be_present
        end
      end
    end

    context 'with include: downstream_pipelines' do
      let_it_be(:downstream_project) { create(:project, maintainers: [user]) }
      let_it_be(:downstream_pipeline) { create(:ci_pipeline, project: downstream_project, status: :running) }
      let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline, status: :success) }

      let(:params) { super().merge(include: ['downstream_pipelines']) }

      before_all do
        create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
      end

      it 'returns pipelines triggered by this pipeline, with the project each one belongs to', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:downstream_pipelines]).to contain_exactly(
          hash_including(id: downstream_pipeline.id, project_full_path: downstream_project.full_path)
        )
      end

      context 'when the user cannot read the downstream pipeline' do
        let_it_be(:private_downstream_project) { create(:project, :private) }
        let_it_be(:private_downstream_pipeline) { create(:ci_pipeline, project: private_downstream_project) }
        let_it_be(:private_bridge) { create(:ci_bridge, pipeline: pipeline, status: :success) }

        before_all do
          create(:ci_sources_pipeline, pipeline: private_downstream_pipeline, source_job: private_bridge)
        end

        it 'excludes it from the results (enforced by Types::Ci::PipelineType authorization)' do
          result = tool.execute

          downstream_ids = result[:structuredContent][:downstream_pipelines].pluck(:id)
          expect(downstream_ids).not_to include(private_downstream_pipeline.id)
        end
      end
    end

    context 'with include: bridge_jobs' do
      let_it_be(:downstream_project) { create(:project, maintainers: [user]) }
      let_it_be(:downstream_pipeline) { create(:ci_pipeline, project: downstream_project, status: :running) }
      let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline, status: :success, name: 'trigger-deploy') }

      let(:params) { super().merge(include: ['bridge_jobs']) }

      before_all do
        create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
      end

      it 'returns the bridge jobs with their downstream pipeline' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        bridge_jobs = result[:structuredContent][:bridge_jobs]
        expect(bridge_jobs.pluck(:id)).to contain_exactly(bridge.id)
        expect(bridge_jobs.first[:downstream_pipeline]).to include(
          id: downstream_pipeline.id, project_full_path: downstream_project.full_path
        )
      end

      context 'when the user cannot read the downstream pipeline' do
        let_it_be(:private_downstream_project) { create(:project, :private) }
        let_it_be(:private_downstream_pipeline) { create(:ci_pipeline, project: private_downstream_project) }
        let_it_be(:private_bridge) { create(:ci_bridge, pipeline: pipeline, status: :success, name: 'trigger-other') }

        before_all do
          create(:ci_sources_pipeline, pipeline: private_downstream_pipeline, source_job: private_bridge)
        end

        it 'omits the downstream pipeline data (enforced by Types::Ci::PipelineType authorization)' do
          result = tool.execute

          bridge_jobs = result[:structuredContent][:bridge_jobs]
          private_bridge_job = bridge_jobs.find { |job| job[:id] == private_bridge.id }
          expect(private_bridge_job[:downstream_pipeline]).to be_nil
        end
      end
    end

    context 'when the pipeline does not exist' do
      let(:params) { { id: project.full_path, pipeline_id: non_existing_record_id } }

      it 'returns a pipeline-not-found error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Pipeline not found')
      end
    end

    context 'when the project does not exist' do
      let(:params) { { id: 'does-not/exist', pipeline_id: pipeline.id } }

      it 'returns the same project-not-found error as an unreadable project', :aggregate_failures do
        expect(GitlabSchema).not_to receive(:execute)

        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Project not found')
      end
    end

    context 'when the user cannot read the pipeline' do
      let_it_be(:outsider) { create(:user) }
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_pipeline) { create(:ci_pipeline, project: private_project) }

      let(:params) { { id: private_project.full_path, pipeline_id: private_pipeline.id } }
      let(:tool) { described_class.new(current_user: outsider, params: params) }

      it 'returns a non-leaky project-not-found error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Project not found')
      end
    end

    context 'when the project is public but its CI/CD data is private' do
      let_it_be(:outsider) { create(:user) }
      let_it_be(:builds_private_project) { create(:project, :public, :builds_private) }
      let_it_be(:hidden_pipeline) { create(:ci_pipeline, project: builds_private_project) }

      let(:params) { { id: builds_private_project.full_path, pipeline_id: hidden_pipeline.id } }
      let(:tool) { described_class.new(current_user: outsider, params: params) }

      it 'returns a pipeline-not-found error, because the project is readable but its pipelines are not' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Pipeline not found')
      end
    end

    context 'when GraphQL returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'errors' => [{ 'message' => 'Boom' }] })
      end

      it 'surfaces the error message' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Boom')
      end
    end
  end
end
