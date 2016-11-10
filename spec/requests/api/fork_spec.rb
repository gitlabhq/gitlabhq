require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user)  { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }
  let(:group2) do
    group = create(:group, name: 'group2_name')
    group.add_owner(user2)
    group
  end

  let(:project) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  let(:project_user2) do
    create(:project_member, :reporter, user: user2, project: project)
  end

  describe 'POST /projects/fork/:id' do
    before { project_user2 }
    before { user3 }

    context 'when authenticated' do
      it 'forks if user has sufficient access to project' do
        post api("/projects/fork/#{project.id}", user2)

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(user2.id)
        expect(json_response['namespace']['id']).to eq(user2.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'forks if user is admin' do
        post api("/projects/fork/#{project.id}", admin)

        expect(response).to have_http_status(201)
        expect(json_response['name']).to eq(project.name)
        expect(json_response['path']).to eq(project.path)
        expect(json_response['owner']['id']).to eq(admin.id)
        expect(json_response['namespace']['id']).to eq(admin.namespace.id)
        expect(json_response['forked_from_project']['id']).to eq(project.id)
      end

      it 'fails on missing project access for the project to fork' do
        post api("/projects/fork/#{project.id}", user3)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'fails if forked project exists in the user namespace' do
        post api("/projects/fork/#{project.id}", user)

        expect(response).to have_http_status(409)
        expect(json_response['message']['name']).to eq(['has already been taken'])
        expect(json_response['message']['path']).to eq(['has already been taken'])
      end

      it 'fails if project to fork from does not exist' do
        post api('/projects/fork/424242', user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end

      it 'forks with explicit own user namespace id' do
        post api("/projects/fork/#{project.id}", user2), namespace: user2.namespace.id

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks with explicit own user name as namespace' do
        post api("/projects/fork/#{project.id}", user2), namespace: user2.username

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'forks to another user when admin' do
        post api("/projects/fork/#{project.id}", admin), namespace: user2.username

        expect(response).to have_http_status(201)
        expect(json_response['owner']['id']).to eq(user2.id)
      end

      it 'fails if trying to fork to another user when not admin' do
        post api("/projects/fork/#{project.id}", user2), namespace: admin.namespace.id

        expect(response).to have_http_status(404)
      end

      it 'fails if trying to fork to non-existent namespace' do
        post api("/projects/fork/#{project.id}", user2), namespace: 42424242

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Target Namespace Not Found')
      end

      it 'forks to owned group' do
        post api("/projects/fork/#{project.id}", user2), namespace: group2.name

        expect(response).to have_http_status(201)
        expect(json_response['namespace']['name']).to eq(group2.name)
      end

      it 'fails to fork to not owned group' do
        post api("/projects/fork/#{project.id}", user2), namespace: group.name

        expect(response).to have_http_status(404)
      end

      it 'forks to not owned group when admin' do
        post api("/projects/fork/#{project.id}", admin), namespace: group.name

        expect(response).to have_http_status(201)
        expect(json_response['namespace']['name']).to eq(group.name)
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/projects/fork/#{project.id}")

        expect(response).to have_http_status(401)
        expect(json_response['message']).to eq('401 Unauthorized')
      end
    end
  end
end
