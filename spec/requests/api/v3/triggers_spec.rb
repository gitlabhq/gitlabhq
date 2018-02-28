require 'spec_helper'

describe API::V3::Triggers do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:trigger_token) { 'secure_token' }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }

  let!(:trigger) do
    create(:ci_trigger, project: project, token: trigger_token, owner: user)
  end

  describe 'POST /projects/:project_id/trigger' do
    let!(:project2) { create(:project) }
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
        post v3_api("/projects/#{project.id}/trigger/builds"), ref: 'master'
        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns not found if project is not found' do
        post v3_api('/projects/0/trigger/builds'), options.merge(ref: 'master')
        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns unauthorized if token is for different project' do
        post v3_api("/projects/#{project2.id}/trigger/builds"), options.merge(ref: 'master')
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'Have a commit' do
      let(:pipeline) { project.pipelines.last }

      it 'creates builds' do
        post v3_api("/projects/#{project.id}/trigger/builds"), options.merge(ref: 'master')
        expect(response).to have_gitlab_http_status(201)
        pipeline.builds.reload
        expect(pipeline.builds.pending.size).to eq(2)
        expect(pipeline.builds.size).to eq(5)
      end

      it 'returns bad request with no builds created if there\'s no commit for that ref' do
        post v3_api("/projects/#{project.id}/trigger/builds"), options.merge(ref: 'other-branch')
        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['base'])
          .to contain_exactly('Reference not found')
      end

      context 'Validates variables' do
        let(:variables) do
          { 'TRIGGER_KEY' => 'TRIGGER_VALUE' }
        end

        it 'validates variables to be a hash' do
          post v3_api("/projects/#{project.id}/trigger/builds"), options.merge(variables: 'value', ref: 'master')
          expect(response).to have_gitlab_http_status(400)
          expect(json_response['error']).to eq('variables is invalid')
        end

        it 'validates variables needs to be a map of key-valued strings' do
          post v3_api("/projects/#{project.id}/trigger/builds"), options.merge(variables: { key: %w(1 2) }, ref: 'master')
          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to eq('variables needs to be a map of key-valued strings')
        end

        it 'creates trigger request with variables' do
          post v3_api("/projects/#{project.id}/trigger/builds"), options.merge(variables: variables, ref: 'master')
          expect(response).to have_gitlab_http_status(201)
          pipeline.builds.reload
          expect(pipeline.variables.map { |v| { v.key => v.value } }.first).to eq(variables)
          expect(json_response['variables']).to eq(variables)
        end
      end
    end

    context 'when triggering a pipeline from a trigger token' do
      it 'creates builds from the ref given in the URL, not in the body' do
        expect do
          post v3_api("/projects/#{project.id}/ref/master/trigger/builds?token=#{trigger_token}"), { ref: 'refs/heads/other-branch' }
        end.to change(project.builds, :count).by(5)
        expect(response).to have_gitlab_http_status(201)
      end

      context 'when ref contains a dot' do
        it 'creates builds from the ref given in the URL, not in the body' do
          project.repository.create_file(user, '.gitlab/gitlabhq/new_feature.md', 'something valid', message: 'new_feature', branch_name: 'v.1-branch')

          expect do
            post v3_api("/projects/#{project.id}/ref/v.1-branch/trigger/builds?token=#{trigger_token}"), { ref: 'refs/heads/other-branch' }
          end.to change(project.builds, :count).by(4)

          expect(response).to have_gitlab_http_status(201)
        end
      end
    end
  end

  describe 'GET /projects/:id/triggers' do
    context 'authenticated user with valid permissions' do
      it 'returns list of triggers' do
        get v3_api("/projects/#{project.id}/triggers", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_a(Array)
        expect(json_response[0]).to have_key('token')
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return triggers list' do
        get v3_api("/projects/#{project.id}/triggers", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get v3_api("/projects/#{project.id}/triggers")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/triggers/:token' do
    context 'authenticated user with valid permissions' do
      it 'returns trigger details' do
        get v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_a(Hash)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        get v3_api("/projects/#{project.id}/triggers/abcdef012345", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not return triggers list' do
        get v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not return triggers list' do
        get v3_api("/projects/#{project.id}/triggers/#{trigger.token}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/triggers' do
    context 'authenticated user with valid permissions' do
      it 'creates trigger' do
        expect do
          post v3_api("/projects/#{project.id}/triggers", user)
        end.to change {project.triggers.count}.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response).to be_a(Hash)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not create trigger' do
        post v3_api("/projects/#{project.id}/triggers", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not create trigger' do
        post v3_api("/projects/#{project.id}/triggers")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /projects/:id/triggers/:token' do
    context 'authenticated user with valid permissions' do
      it 'deletes trigger' do
        expect do
          delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user)

          expect(response).to have_gitlab_http_status(200)
        end.to change {project.triggers.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        delete v3_api("/projects/#{project.id}/triggers/abcdef012345", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete trigger' do
        delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user2)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete trigger' do
        delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
