require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:trigger_token) { 'secure_token' }
  let!(:trigger_token_2) { 'secure_token_2' }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let!(:trigger) { create(:ci_trigger, project: project, token: trigger_token) }
  let!(:trigger2) { create(:ci_trigger, project: project, token: trigger_token_2) }
  let!(:trigger_request) { create(:ci_trigger_request, trigger: trigger, created_at: '2015-01-01 12:13:14') }

  describe 'POST /projects/:project_id/trigger' do
    let!(:project2) { create(:empty_project) }
    let(:options) do
      {
        token: trigger_token
      }
    end

    before do
      stub_ci_commit_to_return_yaml_file
    end

    context 'Handles errors' do
      it 'should return bad request if token is missing' do
        post api("/projects/#{project.id}/trigger/builds"), ref: 'master'
        expect(response.status).to eq(400)
      end

      it 'should return not found if project is not found' do
        post api('/projects/0/trigger/builds'), options.merge(ref: 'master')
        expect(response.status).to eq(404)
      end

      it 'should return unauthorized if token is for different project' do
        post api("/projects/#{project2.id}/trigger/builds"), options.merge(ref: 'master')
        expect(response.status).to eq(401)
      end
    end

    context 'Have a commit' do
      let(:commit) { project.ci_commits.last }

      it 'should create builds' do
        post api("/projects/#{project.id}/trigger/builds"), options.merge(ref: 'master')
        expect(response.status).to eq(201)
        commit.builds.reload
        expect(commit.builds.size).to eq(2)
      end

      it 'should return bad request with no builds created if there\'s no commit for that ref' do
        post api("/projects/#{project.id}/trigger/builds"), options.merge(ref: 'other-branch')
        expect(response.status).to eq(400)
        expect(json_response['message']).to eq('No builds created')
      end

      context 'Validates variables' do
        let(:variables) do
          { 'TRIGGER_KEY' => 'TRIGGER_VALUE' }
        end

        it 'should validate variables to be a hash' do
          post api("/projects/#{project.id}/trigger/builds"), options.merge(variables: 'value', ref: 'master')
          expect(response.status).to eq(400)
          expect(json_response['message']).to eq('variables needs to be a hash')
        end

        it 'should validate variables needs to be a map of key-valued strings' do
          post api("/projects/#{project.id}/trigger/builds"), options.merge(variables: { key: %w(1 2) }, ref: 'master')
          expect(response.status).to eq(400)
          expect(json_response['message']).to eq('variables needs to be a map of key-valued strings')
        end

        it 'create trigger request with variables' do
          post api("/projects/#{project.id}/trigger/builds"), options.merge(variables: variables, ref: 'master')
          expect(response.status).to eq(201)
          commit.builds.reload
          expect(commit.builds.first.trigger_request.variables).to eq(variables)
        end
      end
    end
  end

  describe 'GET /projects/:id/triggers' do
    context 'authenticated user with valid permissions' do
      it 'should return list of triggers' do
        get api("/projects/#{project.id}/triggers", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_a(Array)
        expect(json_response[0]).to have_key('token')
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'should not return triggers list' do
        get api("/projects/#{project.id}/triggers", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthenticated user' do
      it 'should not return triggers list' do
        get api("/projects/#{project.id}/triggers")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/triggers/:token' do
    context 'authenticated user with valid permissions' do
      it 'should return trigger details' do
        get api("/projects/#{project.id}/triggers/#{trigger.token}", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_a(Hash)
      end

      it 'should respond with 404 Not Found if requesting non-existing trigger' do
        get api("/projects/#{project.id}/triggers/abcdef012345", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'should not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.token}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthenticated user' do
      it 'should not return triggers list' do
        get api("/projects/#{project.id}/triggers/#{trigger.token}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects/:id/triggers' do
    context 'authenticated user with valid permissions' do
      it 'should create trigger' do
        expect do
          post api("/projects/#{project.id}/triggers", user)
        end.to change{project.triggers.count}.by(1)

        expect(response.status).to eq(201)
        expect(json_response).to be_a(Hash)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'should not create trigger' do
        post api("/projects/#{project.id}/triggers", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthenticated user' do
      it 'should not create trigger' do
        post api("/projects/#{project.id}/triggers")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'DELETE /projects/:id/triggers/:token' do
    context 'authenticated user with valid permissions' do
      it 'should delete trigger' do
        expect do
          delete api("/projects/#{project.id}/triggers/#{trigger.token}", user)
        end.to change{project.triggers.count}.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should respond with 404 Not Found if requesting non-existing trigger' do
        delete api("/projects/#{project.id}/triggers/abcdef012345", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'should not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.token}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthenticated user' do
      it 'should not delete trigger' do
        delete api("/projects/#{project.id}/triggers/#{trigger.token}")

        expect(response.status).to eq(401)
      end
    end
  end
end
