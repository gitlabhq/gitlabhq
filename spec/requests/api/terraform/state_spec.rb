# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::State, :snowplow, feature_category: :infrastructure_as_code do
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  let(:current_user) { maintainer }
  let(:auth_header) { user_basic_auth_header(current_user) }
  let(:project_id) { project.id }

  let(:state_name) { "some-state" }
  let(:state_path) { "/projects/#{project_id}/terraform/state/#{state_name}" }
  let!(:state) do
    create(:terraform_state, :with_version, project: project, name: URI.decode_www_form_component(state_name))
  end

  before do
    stub_terraform_state_object_storage
    stub_config(terraform_state: { enabled: true })
  end

  shared_examples 'endpoint with unique user tracking' do
    context 'without authentication' do
      let(:auth_header) { basic_auth_header('bad', 'token') }

      it 'does not track unique hll event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        request
      end

      it 'does not track Snowplow event' do
        request

        expect_no_snowplow_event
      end
    end

    context 'with maintainer permissions' do
      let(:current_user) { maintainer }

      it_behaves_like 'tracking unique hll events' do
        let(:target_event) { 'p_terraform_state_api_unique_users' }
        let(:expected_value) { instance_of(Integer) }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject(:api_request) { request }

        let(:category) { described_class.name }
        let(:action) { 'terraform_state_api_request' }
        let(:label) { 'redis_hll_counters.terraform.p_terraform_state_api_unique_users_monthly' }
        let(:namespace) { project.namespace.reload }
        let(:user) { current_user }
        let(:context) do
          payload = Gitlab::Tracking::ServicePingContext.new(
            data_source: :redis_hll,
            event: 'p_terraform_state_api_unique_users'
          ).to_context
          [Gitlab::Json.dump(payload)]
        end
      end
    end
  end

  shared_context 'cannot access a state that is scheduled for deletion' do
    before do
      state.update!(deleted_at: Time.current)
    end

    it 'returns unprocessable entity' do
      request

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /projects/:id/terraform/state/:name' do
    subject(:request) { get api(state_path), headers: auth_header }

    it_behaves_like 'endpoint with unique user tracking'
    it_behaves_like 'it depends on value of the `terraform_state.enabled` config'

    context 'without authentication' do
      let(:auth_header) { basic_auth_header('bad', 'token') }

      it 'returns 401 if user is not authenticated' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    shared_examples 'can access terraform state' do
      it 'returns terraform state of a project of given state name' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(state.reload.latest_file.read)
      end
    end

    context 'personal access token authentication' do
      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        where(given_state_name: %w[test-state test.state test%2Ffoo])
        with_them do
          it_behaves_like 'can access terraform state' do
            let(:state_name) { given_state_name }
          end
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'with invalid state name' do
          let(:state_name) { 'foo/bar' }

          it 'returns a 404 error' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        it_behaves_like 'cannot access a state that is scheduled for deletion'
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it_behaves_like 'can access terraform state'
      end
    end

    context 'job token authentication' do
      let(:auth_header) { job_basic_auth_header(job) }

      it_behaves_like 'enforcing job token policies', :read_terraform_state do
        let_it_be(:user) { maintainer }
        let(:job) { target_job }
      end

      context 'with maintainer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: maintainer) }

        it_behaves_like 'can access terraform state'

        it 'returns unauthorized if the the job is not running' do
          job.update!(status: :failed)
          request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with developer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: developer) }

        it_behaves_like 'can access terraform state'
      end
    end
  end

  describe 'POST /projects/:id/terraform/state/:name' do
    let(:params) { { instance: 'example-instance', serial: state.latest_version.version + 1 } }

    subject(:request) { post api(state_path), headers: auth_header, as: :json, params: params }

    it_behaves_like 'endpoint with unique user tracking'
    it_behaves_like 'it depends on value of the `terraform_state.enabled` config'

    context 'when terraform state with a given name is already present' do
      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        where(given_state_name: %w[test-state test.state test%2Ffoo])
        with_them do
          let(:state_name) { given_state_name }

          it 'updates the state' do
            expect { request }.to change { Terraform::State.count }.by(0)

            expect(response).to have_gitlab_http_status(:ok)
            expect(Gitlab::Json.parse(response.body)).to be_empty
          end
        end

        context 'with invalid state name' do
          let(:state_name) { 'foo/bar' }

          it 'returns a 404 error' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when serial already exists' do
          let(:params) { { instance: 'example-instance', serial: state.latest_version.version } }

          it 'returns unprocessable entity' do
            request

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end

        it_behaves_like 'cannot access a state that is scheduled for deletion'
      end

      context 'without body' do
        let(:params) { nil }

        it 'returns no content if no body is provided' do
          request

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns forbidden' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when there is no terraform state of a given name' do
      let(:non_existing_state_name) { 'non-existing-state' }
      let(:non_existing_state_path) { "/projects/#{project_id}/terraform/state/#{non_existing_state_name}" }

      subject(:request) { post api(non_existing_state_path), headers: auth_header, as: :json, params: params }

      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        where(given_state_name: %w[test-state test.state test%2Ffoo])
        with_them do
          let(:state_name) { given_state_name }

          it 'creates a new state' do
            expect { request }.to change { Terraform::State.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
            expect(Gitlab::Json.parse(response.body)).to be_empty
          end
        end
      end

      context 'without body' do
        let(:params) { nil }

        it 'returns no content if no body is provided' do
          request

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns forbidden' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when using job token authentication' do
      let(:job) { create(:ci_build, status: :running, project: project, user: maintainer) }
      let(:auth_header) { job_basic_auth_header(job) }

      it_behaves_like 'enforcing job token policies', :admin_terraform_state do
        let_it_be(:user) { maintainer }
        let(:job) { target_job }
      end

      it 'associates the job with the newly created state version' do
        expect { request }.to change { state.versions.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(state.reload_latest_version.build).to eq(job)
      end
    end

    describe 'response depending on the max allowed state size' do
      let(:current_user) { maintainer }

      before do
        stub_application_setting(max_terraform_state_size_bytes: max_allowed_state_size)

        request
      end

      context 'when the max allowed state size is unlimited (set as 0)' do
        let(:max_allowed_state_size) { 0 }

        it 'returns a success response' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the max allowed state size is greater than the request state size' do
        let(:max_allowed_state_size) { params.to_json.size + 1 }

        it 'returns a success response' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the max allowed state size is equal to the request state size' do
        let(:max_allowed_state_size) { params.to_json.size }

        it 'returns a success response' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the max allowed state size is less than the request state size' do
        let(:max_allowed_state_size) { params.to_json.size - 1 }

        it "returns a 'payload too large' response" do
          expect(response).to have_gitlab_http_status(:payload_too_large)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name' do
    subject(:request) { delete api(state_path), headers: auth_header }

    it_behaves_like 'enforcing job token policies', :admin_terraform_state do
      let_it_be(:user) { maintainer }
      let(:auth_header) { job_basic_auth_header(target_job) }
    end

    it_behaves_like 'endpoint with unique user tracking'
    it_behaves_like 'it depends on value of the `terraform_state.enabled` config'

    shared_examples 'schedules the state for deletion' do
      it 'returns empty body' do
        expect(Terraform::States::TriggerDestroyService).to receive(:new).and_return(deletion_service)
        expect(deletion_service).to receive(:execute).once

        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to be_empty
      end
    end

    context 'with maintainer permissions' do
      let(:current_user) { maintainer }
      let(:deletion_service) { instance_double(Terraform::States::TriggerDestroyService) }

      where(given_state_name: %w[test-state test.state test%2Ffoo])
      with_them do
        let(:state_name) { given_state_name }

        it_behaves_like 'schedules the state for deletion'
      end

      context 'with invalid state name' do
        let(:state_name) { 'foo/bar' }

        it 'returns a 404 error' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'cannot access a state that is scheduled for deletion'
    end

    context 'with developer permissions' do
      let(:current_user) { developer }

      it 'returns forbidden' do
        expect { request }.to change { Terraform::State.count }.by(0)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/:id/terraform/state/:name/lock' do
    let(:params) do
      {
        ID: '123-456',
        Version: '0.1',
        Operation: 'OperationTypePlan',
        Info: '',
        Who: current_user.username.to_s,
        Created: Time.now.utc.iso8601(6),
        Path: ''
      }
    end

    subject(:request) { post api("#{state_path}/lock"), headers: auth_header, params: params }

    it_behaves_like 'enforcing job token policies', :admin_terraform_state do
      let_it_be(:user) { maintainer }
      let(:auth_header) { job_basic_auth_header(target_job) }
    end

    it_behaves_like 'endpoint with unique user tracking'
    it_behaves_like 'cannot access a state that is scheduled for deletion'

    context 'with invalid state name' do
      let(:state_name) { 'foo/bar' }

      it 'returns a 404 error' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'state is already locked' do
      before do
        state.update!(lock_xid: 'locked', locked_by_user: current_user)
      end

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:conflict)
        expect(Gitlab::Json.parse(response.body)).to include('Who' => current_user.username)
      end
    end

    context 'user does not have permission to lock the state' do
      let(:current_user) { developer }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    where(given_state_name: %w[test-state test%2Ffoo])
    with_them do
      let(:state_name) { given_state_name }

      it 'locks the terraform state' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a dot in the state name' do
      let(:state_name) { 'test.state' }

      it 'locks the terraform state' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name/lock' do
    let(:params) do
      {
        ID: lock_id,
        Version: '0.1',
        Operation: 'OperationTypePlan',
        Info: '',
        Who: current_user.username.to_s,
        Created: Time.now.utc.iso8601(6),
        Path: ''
      }
    end

    before do
      state.lock_xid = '123.456'
      state.save!
    end

    subject(:request) { delete api("#{state_path}/lock"), headers: auth_header, params: params }

    it_behaves_like 'enforcing job token policies', :admin_terraform_state do
      let_it_be(:user) { maintainer }
      let(:auth_header) { job_basic_auth_header(target_job) }
      let(:lock_id) { '123.456' }
    end

    it_behaves_like 'endpoint with unique user tracking' do
      let(:lock_id) { 'irrelevant to this test, just needs to be present' }
    end

    it_behaves_like 'cannot access a state that is scheduled for deletion' do
      let(:lock_id) { 'irrelevant to this test, just needs to be present' }
    end

    it_behaves_like 'it depends on value of the `terraform_state.enabled` config' do
      let(:lock_id) { '123.456' }
    end

    where(given_state_name: %w[test-state test.state test%2Ffoo])
    with_them do
      let(:state_name) { given_state_name }

      context 'with the correct lock id' do
        let(:lock_id) { '123.456' }

        it 'removes the terraform state lock' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with no lock id (force-unlock)' do
        let(:params) { {} }

        it 'removes the terraform state lock' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with invalid state name' do
      let(:lock_id) { '123.456' }
      let(:state_name) { 'foo/bar' }

      it 'returns a 404 error' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an incorrect lock id' do
      let(:lock_id) { '456.789' }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:conflict)
      end
    end

    context 'with a longer than 255 character lock id' do
      let(:lock_id) { '0' * 256 }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'user does not have permission to unlock the state' do
      let(:lock_id) { '123.456' }
      let(:current_user) { developer }

      it 'returns an error' do
        request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
