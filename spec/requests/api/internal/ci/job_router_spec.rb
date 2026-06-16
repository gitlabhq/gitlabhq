# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Ci::JobRouter, feature_category: :continuous_integration do
  include StubGitlabCalls

  let_it_be(:runner) { create(:ci_runner, :instance) }

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }
  let(:jwt_token) do
    JWT.encode(
      { 'iss' => Gitlab::Kas::JWT_ISSUER, 'aud' => Gitlab::Kas::JWT_AUDIENCE },
      jwt_secret,
      'HS256'
    )
  end

  let(:kas_headers) { { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => jwt_token } }

  before do
    allow(Gitlab::Kas).to receive_messages(enabled?: true, secret: jwt_secret)
  end

  describe 'GET /internal/ci/agents/runner/info' do
    subject(:request) { get api('/internal/ci/agents/runner/info'), headers: headers.reverse_merge(kas_headers) }

    context 'when not authenticated' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => '' } }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when no Gitlab-Agent-Api-Request header is sent' do
      let(:headers) { {} }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when Gitlab-Agent-Api-Request header is for non-existent agent' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => 'NONEXISTENT' } }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when a runner is found' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => runner.token } }

      it 'returns expected data' do
        request

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response).to eq('runner_id' => runner.id)
      end
    end
  end

  describe 'POST /internal/ci/job_router/jobs/request' do
    let_it_be(:project) { create(:project, :empty_repo, shared_runners_enabled: true) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }

    let(:params) { { token: runner.token, system_id: 's_some_system_id' } }
    let(:headers) { kas_headers }

    subject(:perform_request) do
      post api('/internal/ci/job_router/jobs/request'), params: params, headers: headers
    end

    before do
      stub_gitlab_calls
      stub_container_registry_config(enabled: false)
    end

    context 'when a job is available' do
      let!(:job) { create(:ci_build, :pending, :queued, pipeline: pipeline) }

      it 'returns the job shaped by the Job Router entity', :aggregate_failures do
        perform_request

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include('id' => job.id, 'token' => job.token)
        expect(json_response).to include('job_info', 'git_info')
      end
    end

    context 'when no job is available' do
      it 'returns no content with a fresh queue update header', :aggregate_failures do
        perform_request

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.header['X-GitLab-Last-Update']).to be_present
      end
    end

    context 'when the runner queue is already up to date' do
      let(:last_update) { runner.ensure_runner_queue_value }
      let(:params) { { token: runner.token, last_update: last_update } }

      it 'returns no content and echoes the supplied queue value', :aggregate_failures do
        perform_request

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.header['X-GitLab-Last-Update']).to eq(last_update)
      end
    end

    context 'when the job is invalid due to a concurrency conflict' do
      before do
        allow_next_instance_of(::Ci::RegisterJobService) do |service|
          allow(service).to receive(:execute).and_return(
            ::Ci::RegisterJobService::Result.new(build: nil, build_json: nil, build_presented: nil, valid?: false)
          )
        end
      end

      it 'returns conflict' do
        perform_request

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'when the runner is not active' do
      let_it_be(:paused_runner) { create(:ci_runner, :instance, :paused) }

      let(:params) { { token: paused_runner.token } }

      it 'returns no content with the queue update header', :aggregate_failures do
        perform_request

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.header['X-GitLab-Last-Update']).to be_present
      end
    end

    context 'when the runner token is invalid' do
      let(:params) { { token: 'invalid' } }

      it 'returns 403' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the Job Router is disabled' do
      before do
        stub_feature_flags(job_router_instance_runners: false, job_router: false)
      end

      it 'returns 501' do
        perform_request

        expect(response).to have_gitlab_http_status(:not_implemented)
      end
    end

    context 'when KAS is enabled but the request is not authenticated' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => '' } }

      it 'returns 401' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
