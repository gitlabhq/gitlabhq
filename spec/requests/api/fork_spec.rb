require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user)  { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }

  let(:project) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  let(:project_user2) do
    create(:project_member, :guest, user: user2, project: project)
  end

  describe 'POST /projects/fork/:id' do
    before { project_user2 }
    before { user3 }

    context 'when authenticated' do
      it 'should fork if user has sufficient access to project' do
        post api("/projects/fork/#{project.id}", user2)
        expect(response.status).to eq(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'should fork if user is admin' do
        post api("/projects/fork/#{project.id}", admin)
        expect(response.status).to eq(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(admin.id)
        expect(json_response['namespace']['id']).to eq(admin.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'should fail on missing project access for the project to fork' do
        post api("/projects/fork/#{project.id}", user3)
        expect(response.status).to eq(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'should fail if forked project exists in the user namespace' do
        post api("/projects/fork/#{project.id}", user)
        expect(response.status).to eq(409)
        expect(json_response['message']['name']).to eq(['has already been taken'])
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'should fail if project to fork from does not exist' do
        post api('/projects/fork/424242', user)
        expect(response.status).to eq(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    context 'when unauthenticated' do
      it 'should return authentication error' do
        post api("/projects/fork/#{project.id}")
        expect(response.status).to eq(401)
        expect(json_response['message']).to eq('401 Unauthorized')
      end
    end
  end
end
