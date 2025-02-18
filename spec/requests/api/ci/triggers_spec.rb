# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Triggers, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, creator: user) }
  let_it_be_with_reload(:project2) { create(:project, :repository) }
  let_it_be(:trigger_token) { 'secure_token' }
  let_it_be(:trigger_token_2) { 'secure_token_2' }
  let_it_be(:maintainer) { create(:project_member, :maintainer, user: user, project: project) }
  let_it_be(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let_it_be(:trigger) { create(:ci_trigger, project: project, token: trigger_token, owner: user) }
  let_it_be(:trigger2) { create(:ci_trigger, project: project, token: trigger_token_2, owner: user2) }
  let_it_be(:trigger_request) { create(:ci_trigger_request, trigger: trigger, created_at: '2015-01-01 12:13:14') }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
  end

  describe 'POST /projects/:project_id/trigger/pipeline' do
    let(:options) do
      {
        token: trigger_token
      }
    end

    before do
      stub_ci_pipeline_to_return_yaml_file
    end

    context 'Handles errors' do
      it 'returns bad request if token is missing' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: { ref: 'master' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns not found if project is not found' do
        post api('/projects/0/trigger/pipeline'), params: options.merge(ref: 'master')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'Have a commit' do
      let(:pipeline) { project.ci_pipelines.last }

      it 'creates pipeline' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(ref: 'master')

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include('id' => pipeline.id)
        expect(pipeline.builds.size).to eq(5)
      end

      it 'stores payload as a variable' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(ref: 'master')

        expect(response).to have_gitlab_http_status(:created)
        expect(pipeline.variables.find { |v| v.key == 'TRIGGER_PAYLOAD' }.value).to eq(
          "{\"ref\":\"master\",\"id\":\"#{project.id}\",\"variables\":{}}"
        )
      end

      it 'returns bad request with no pipeline created if there\'s no commit for that ref' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(ref: 'other-branch')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('base' => ["Reference not found"])
      end

      context 'Validates variables' do
        let(:variables) do
          { 'TRIGGER_KEY' => 'TRIGGER_VALUE' }
        end

        it 'validates variables to be a hash' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: 'value', ref: 'master')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('variables is invalid')
        end

        it 'validates variables needs to be a map of key-valued strings' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: { 'TRIGGER_KEY' => %w[1 2] }, ref: 'master')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('variables needs to be a map of key-valued strings')
        end

        it 'creates trigger request with variables' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: variables, ref: 'master')

          expect(response).to have_gitlab_http_status(:created)
          expect(pipeline.variables.find { |v| v.key == 'TRIGGER_KEY' }.value).to eq('TRIGGER_VALUE')
        end
      end
    end

    context 'when triggering a pipeline from a trigger token' do
      it 'does not leak the presence of project when token is for different project' do
        post api("/projects/#{project2.id}/ref/master/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'creates builds from the ref given in the URL, not in the body' do
        expect do
          post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }
        end.to change(project.builds, :count).by(5)

        expect(response).to have_gitlab_http_status(:created)
      end

      context 'when ref contains a dot' do
        it 'creates builds from the ref given in the URL, not in the body' do
          project.repository.create_file(user, '.gitlab/gitlabhq/new_feature.md', 'something valid', message: 'new_feature', branch_name: 'v.1-branch')

          expect do
            post api("/projects/#{project.id}/ref/v.1-branch/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }
          end.to change(project.builds, :count).by(4)

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    it_behaves_like 'logs inbound authorizations via job token', :created, :not_found do
      let(:accessed_project) { project }
      let(:origin_project) { project2 }

      let(:perform_request) do
        post api("/projects/#{accessed_project.id}/ref/master/trigger/pipeline?token=#{job_token}"),
          params: { ref: 'master' }
      end
    end

    describe 'adding arguments to the application context' do
      subject { subject_proc.call }

      let(:expected_params) { { client_id: "user/#{user.id}", project: project.full_path } }
      let(:subject_proc) { proc { post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' } } }

      context 'when triggering a pipeline from a trigger token' do
        it_behaves_like 'storing arguments in the application context for the API'
        it_behaves_like 'not executing any extra queries for the application context'
      end

      context 'when triggered from another running job' do
        let!(:trigger) {}
        let!(:trigger_request) {}

        context 'when other job is triggered by a user' do
          let(:trigger_token) { create(:ci_build, :running, project: project, user: user).token }

          it_behaves_like 'storing arguments in the application context for the API'
          it_behaves_like 'not executing any extra queries for the application context'
        end

        context 'when other job is triggered by a runner' do
          let(:trigger_token) { create(:ci_build, :running, project: project, runner: runner).token }
          let(:runner) { create(:ci_runner) }
          let(:expected_params) { { client_id: "runner/#{runner.id}", project: project.full_path } }

          it_behaves_like 'storing arguments in the application context for the API'
          it_behaves_like 'not executing any extra queries for the application context', 1
        end
      end
    end

    context 'when is triggered by a pipeline hook' do
      it 'does not create a new pipeline' do
        expect do
          post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{trigger_token}"),
            params: { ref: 'refs/heads/other-branch' },
            headers: { ::Gitlab::WebHooks::GITLAB_EVENT_HEADER => 'Pipeline Hook' }
        end.not_to change(Ci::Pipeline, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/triggers' do
    context 'authenticated user who can access triggers' do
      it 'returns a list of triggers with tokens exposed correctly' do
        get api("/projects/#{project.id}/triggers", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers

        expect(json_response).to be_a(Array)
        expect(json_response.size).to eq 2
        expect(json_response.dig(0, 'token')).to eq trigger_token
        expect(json_response.dig(1, 'token')).to eq trigger_token_2[0..3]
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/triggers/:trigger_id' do
    context 'authenticated user with valid permissions' do
      it 'returns trigger details' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Hash)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        get api("/projects/#{project.id}/triggers/-5", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/triggers' do
    context 'authenticated user with valid permissions' do
      context 'with required parameters' do
        it 'creates trigger' do
          expect do
            post api("/projects/#{project.id}/triggers", user),
              params: { description: 'trigger' }
          end.to change { project.triggers.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to include('description' => 'trigger')
        end
      end

      context 'without required parameters' do
        it 'does not create trigger' do
          expect do
            post api("/projects/#{project.id}/triggers", user)
          end.not_to change { project.triggers.count }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with optional parameters' do
        it 'creates trigger with expiration' do
          date = DateTime.now + 20.days

          expect do
            post api("/projects/#{project.id}/triggers", user),
              params: { description: 'trigger', expires_at: date.iso8601(3) }
          end.to change { project.triggers.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to include('description' => 'trigger')
          expect(json_response).to include('expires_at' => date.utc.iso8601(3))
        end
      end

      context 'when trigger expiration past limit' do
        it 'does not create trigger' do
          date = DateTime.now + 20.years

          expect do
            post api("/projects/#{project.id}/triggers", user),
              params: { description: 'trigger', expires_at: date.iso8601(3) }
          end.not_to change { project.triggers.count }

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'creates trigger when feature flag turned off' do
          stub_feature_flags(trigger_token_expiration: false)

          date = DateTime.now + 20.years

          expect do
            post api("/projects/#{project.id}/triggers", user),
              params: { description: 'trigger', expires_at: date.iso8601(3) }
          end.to change { project.triggers.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to include('description' => 'trigger')
          expect(json_response).to include('expires_at' => nil)
        end
      end

      context 'when expiration is invalid date string' do
        [
          'abc',
          '01/01/2050',
          '25/26/27',
          '2308'
        ].each do |param|
          it "rejects #{param}" do
            expect do
              post api("/projects/#{project.id}/triggers", user),
                params: { description: 'trigger', expires_at: param }
            end.not_to change { project.triggers.count }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when the CreateService returns a permissions error' do
        before do
          failure_response = instance_double(ServiceResponse, success?: false, reason: :forbidden, message: "Permissions error message")

          allow_next_instance_of(::Ci::PipelineTriggers::CreateService) do |instance|
            allow(instance).to receive(:execute)
                      .and_return(failure_response)
          end
        end

        it 'returns forbidden' do
          post api("/projects/#{project.id}/triggers", user),
            params: { description: 'trigger' }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('403 Forbidden - Permissions error message')
        end
      end

      context 'when trigger fails to save' do
        before do
          failure_response = instance_double(ServiceResponse, success?: false, reason: :validation_error, message: "Unexpected Ci::Trigger creation failure")

          allow_next_instance_of(::Ci::PipelineTriggers::CreateService) do |instance|
            allow(instance).to receive(:execute)
                      .and_return(failure_response)
          end
        end

        it 'returns bad request' do
          post api("/projects/#{project.id}/triggers", user),
            params: { description: 'trigger' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('400 Bad request - Unexpected Ci::Trigger creation failure')
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create trigger' do
        post api("/projects/#{project.id}/triggers", user2),
          params: { description: 'trigger' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not create trigger' do
        post api("/projects/#{project.id}/triggers"),
          params: { description: 'trigger' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /projects/:id/triggers/:trigger_id' do
    context 'user is maintainer of the project' do
      context 'the trigger belongs to user' do
        let(:new_description) { 'new description' }

        it 'updates description' do
          put api("/projects/#{project.id}/triggers/#{trigger.id}", user),
            params: { description: new_description }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include('description' => new_description)
          expect(trigger.reload.description).to eq(new_description)
        end
      end

      context 'the trigger does not belong to user' do
        it 'does not update trigger' do
          put api("/projects/#{project.id}/triggers/#{trigger2.id}", user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'user is developer of the project' do
      context 'the trigger belongs to user' do
        it 'does not update trigger' do
          put api("/projects/#{project.id}/triggers/#{trigger2.id}", user2)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'the trigger does not belong to user' do
        it 'does not update trigger' do
          put api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'unauthenticated user' do
      it 'does not update trigger' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the UpdateService returns a permissions error' do
      before do
        failure_response = instance_double(ServiceResponse, success?: false, reason: :forbidden, message: "Permissions error message")

        allow_next_instance_of(::Ci::PipelineTriggers::UpdateService) do |instance|
          allow(instance).to receive(:execute)
                    .and_return(failure_response)
        end
      end

      it 'returns forbidden' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}", user),
          params: { description: 'updated trigger' }

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden - Permissions error message')
      end
    end

    context 'when trigger fails to update' do
      before do
        failure_response = instance_double(ServiceResponse, success?: false, reason: :validation_error, message: "Unexpected Ci::Trigger update failure")

        allow_next_instance_of(::Ci::PipelineTriggers::UpdateService) do |instance|
          allow(instance).to receive(:execute)
                    .and_return(failure_response)
        end
      end

      it 'returns bad request' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}", user),
          params: { description: 'updated trigger' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('400 Bad request - Unexpected Ci::Trigger update failure')
      end
    end
  end

  describe 'DELETE /projects/:id/triggers/:trigger_id' do
    context 'authenticated user with valid permissions' do
      it 'deletes trigger' do
        expect do
          delete api("/projects/#{project.id}/triggers/#{trigger.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { project.triggers.count }.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        delete api("/projects/#{project.id}/triggers/-5", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/triggers/#{trigger.id}", user) }
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
