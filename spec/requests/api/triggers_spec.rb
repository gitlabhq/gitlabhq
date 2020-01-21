# frozen_string_literal: true

require 'spec_helper'

describe API::Triggers do
  set(:user) { create(:user) }
  set(:user2) { create(:user) }

  let!(:trigger_token) { 'secure_token' }
  let!(:trigger_token_2) { 'secure_token_2' }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:maintainer) { create(:project_member, :maintainer, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let!(:trigger) { create(:ci_trigger, project: project, token: trigger_token, owner: user) }
  let!(:trigger2) { create(:ci_trigger, project: project, token: trigger_token_2, owner: user2) }
  let!(:trigger_request) { create(:ci_trigger_request, trigger: trigger, created_at: '2015-01-01 12:13:14') }

  describe 'POST /projects/:project_id/trigger/pipeline' do
    let!(:project2) { create(:project, :repository) }
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

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns not found if project is not found' do
        post api('/projects/0/trigger/pipeline'), params: options.merge(ref: 'master')

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'Have a commit' do
      let(:pipeline) { project.ci_pipelines.last }

      it 'creates pipeline' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(ref: 'master')

        expect(response).to have_gitlab_http_status(201)
        expect(json_response).to include('id' => pipeline.id)
        pipeline.builds.reload
        expect(pipeline.builds.pending.size).to eq(2)
        expect(pipeline.builds.size).to eq(5)
      end

      it 'returns bad request with no pipeline created if there\'s no commit for that ref' do
        post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(ref: 'other-branch')

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('base' => ["Reference not found"])
      end

      context 'Validates variables' do
        let(:variables) do
          { 'TRIGGER_KEY' => 'TRIGGER_VALUE' }
        end

        it 'validates variables to be a hash' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: 'value', ref: 'master')

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['error']).to eq('variables is invalid')
        end

        it 'validates variables needs to be a map of key-valued strings' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: { key: %w(1 2) }, ref: 'master')

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to eq('variables needs to be a map of key-valued strings')
        end

        it 'creates trigger request with variables' do
          post api("/projects/#{project.id}/trigger/pipeline"), params: options.merge(variables: variables, ref: 'master')

          expect(response).to have_gitlab_http_status(201)
          expect(pipeline.variables.map { |v| { v.key => v.value } }.last).to eq(variables)
        end
      end
    end

    context 'when triggering a pipeline from a trigger token' do
      it 'does not leak the presence of project when token is for different project' do
        post api("/projects/#{project2.id}/ref/master/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'creates builds from the ref given in the URL, not in the body' do
        expect do
          post api("/projects/#{project.id}/ref/master/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }
        end.to change(project.builds, :count).by(5)

        expect(response).to have_gitlab_http_status(201)
      end

      context 'when ref contains a dot' do
        it 'creates builds from the ref given in the URL, not in the body' do
          project.repository.create_file(user, '.gitlab/gitlabhq/new_feature.md', 'something valid', message: 'new_feature', branch_name: 'v.1-branch')

          expect do
            post api("/projects/#{project.id}/ref/v.1-branch/trigger/pipeline?token=#{trigger_token}"), params: { ref: 'refs/heads/other-branch' }
          end.to change(project.builds, :count).by(4)

          expect(response).to have_gitlab_http_status(201)
        end
      end
    end
  end

  describe 'GET /projects/:id/triggers' do
    context 'authenticated user who can access triggers' do
      it 'returns a list of triggers with tokens exposed correctly' do
        get api("/projects/#{project.id}/triggers", user)

        expect(response).to have_gitlab_http_status(200)
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

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/triggers/:trigger_id' do
    context 'authenticated user with valid permissions' do
      it 'returns trigger details' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_a(Hash)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        get api("/projects/#{project.id}/triggers/-5", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(401)
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
          end.to change {project.triggers.count}.by(1)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response).to include('description' => 'trigger')
        end
      end

      context 'without required parameters' do
        it 'does not create trigger' do
          post api("/projects/#{project.id}/triggers", user)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create trigger' do
        post api("/projects/#{project.id}/triggers", user2),
          params: { description: 'trigger' }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not create trigger' do
        post api("/projects/#{project.id}/triggers"),
          params: { description: 'trigger' }

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'PUT /projects/:id/triggers/:trigger_id' do
    context 'authenticated user with valid permissions' do
      let(:new_description) { 'new description' }

      it 'updates description' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}", user),
          params: { description: new_description }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to include('description' => new_description)
        expect(trigger.reload.description).to eq(new_description)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not update trigger' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not update trigger' do
        put api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /projects/:id/triggers/:trigger_id' do
    context 'authenticated user with valid permissions' do
      it 'deletes trigger' do
        expect do
          delete api("/projects/#{project.id}/triggers/#{trigger.id}", user)

          expect(response).to have_gitlab_http_status(204)
        end.to change {project.triggers.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        delete api("/projects/#{project.id}/triggers/-5", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/triggers/#{trigger.id}", user) }
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.id}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
