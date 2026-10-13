# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- one spec file per runner route, as with the siblings in this directory
RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :runner_core do
  include StubGitlabCalls

  before do
    stub_gitlab_calls
  end

  describe 'GET /api/v4/jobs/:id/runtime_environment_key' do
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be_with_reload(:runner_manager) { create(:ci_runner_machine, runner: runner) }
    let_it_be(:user) { create(:user) }

    let_it_be_with_reload(:job) do
      create(:ci_build, :pending, pipeline: pipeline, project: project, user: user,
        runner_id: runner.id, runner_manager: runner_manager)
    end

    let(:environment_key) { '42/s_machineid/data' }
    let(:job_id) { job.id }
    let(:job_token) { job.token }

    before do
      job.run!
    end

    def link_runtime_environment(build)
      create(:ci_job_runtime_environment, build: build,
        runtime_environment: create(:ci_runtime_environment, project: project, environment_key: environment_key))
    end

    context 'when the job is linked to a runtime environment' do
      before do
        link_runtime_environment(job)
      end

      it_behaves_like 'API::CI::Runner application context metadata',
        'GET /api/:version/jobs/:id/runtime_environment_key' do
        let(:send_request) { get_runtime_environment_key }
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :runner_jobs_api do
        let(:job2) do
          create(:ci_build, :running, user: user, project: project, pipeline: pipeline, runner_id: runner.id)
        end

        def request
          get_runtime_environment_key
        end

        def request_with_second_scope
          get api("/jobs/#{job2.id}/runtime_environment_key"), params: { token: job2.token }
        end
      end

      it 'returns the runtime environment key' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['runtime_environment_key']).to eq(environment_key)
      end

      it 'accepts the job token in the JOB-TOKEN header instead of a query parameter' do
        get api("/jobs/#{job.id}/runtime_environment_key"),
          headers: { ::API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['runtime_environment_key']).to eq(environment_key)
      end

      context 'when the ci_suspendable_environment_runner_routing feature flag is disabled' do
        before do
          stub_feature_flags(ci_suspendable_environment_runner_routing: false)
        end

        it 'returns not found' do
          get_runtime_environment_key

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when authenticated with another job token' do
        let_it_be(:other_job) do
          create(:ci_build, :running, pipeline: pipeline, project: project, user: user, runner_id: runner.id)
        end

        let(:job_token) { other_job.token }

        it 'returns forbidden and does not leak the key' do
          get_runtime_environment_key

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).not_to include(environment_key)
        end

        it 'logs the token mismatch' do
          expect(Gitlab::AppLogger).to receive(:info).with(a_hash_including(
            job_id: other_job.id,
            auth_fail_reason: 'job_token_mismatch',
            message: 'Job auth error'
          ))
          allow(Gitlab::AppLogger).to receive(:info)

          get_runtime_environment_key
        end
      end

      # A job cannot read back the key produced by its own suspension: that key is written when the
      # job completes, by Ci::RuntimeEnvironments::Record{Successful,Failed}SuspensionService, and
      # authenticate_job! requires the job to still be executing. A resumed job is the reachable
      # case, covered above: Gitlab::Ci::Pipeline::Chain::Create links its Ci::JobRuntimeEnvironment
      # to the existing Ci::RuntimeEnvironment at pipeline creation, so while it runs it can read
      # the key of the environment it resumed into. Nothing in-tree calls the endpoint yet.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252787 for the discussion.
      context 'when the job has already finished' do
        before do
          job.success!
        end

        it 'returns forbidden and does not leak the key' do
          get_runtime_environment_key

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).not_to include(environment_key)
        end
      end
    end

    context 'when the job has no linked runtime environment' do
      it 'returns not found' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when no token is given' do
      let(:job_token) { nil }

      it 'returns forbidden' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the token is invalid' do
      let(:job_token) { 'invalid-token' }

      it 'returns forbidden' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the job has been erased' do
      let(:job) { create(:ci_build, runner_id: runner.id, erased_at: Time.current) }

      it 'returns forbidden' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the job does not exist' do
      let(:job_id) { non_existing_record_id }

      it 'returns forbidden' do
        get_runtime_environment_key

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def get_runtime_environment_key
      get api("/jobs/#{job_id}/runtime_environment_key"), params: { token: job_token }.compact
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
