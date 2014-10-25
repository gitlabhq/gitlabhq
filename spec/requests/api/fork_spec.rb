require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user)  { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project)       {
    create(:project,        creator_id:   user.id,
                            namespace:    user.namespace)
  }
  let(:project_user2) {
    create(:project_member, user:         user2,
                            project:      project,
                            access_level: ProjectMember::GUEST)
  }

  describe 'POST /projects/fork/:id' do
    before { project_user2 }
    before { user3 }

    context 'when authenticated' do
      it 'should fork if user has sufficient access to project' do
        post api("/projects/fork/#{project.id}", user2)
        response.status.should == 201
        json_response['name'].should == project.name
        json_response['path'].should == project.path
        json_response['owner']['id'].should == user2.id
        json_response['namespace']['id'].should == user2.namespace.id
        json_response['forked_from_project']['id'].should == project.id
      end

      it 'should fork if user is admin' do
        post api("/projects/fork/#{project.id}", admin)
        response.status.should == 201
        json_response['name'].should == project.name
        json_response['path'].should == project.path
        json_response['owner']['id'].should == admin.id
        json_response['namespace']['id'].should == admin.namespace.id
        json_response['forked_from_project']['id'].should == project.id
      end

      it 'should fail on missing project access for the project to fork' do
        post api("/projects/fork/#{project.id}", user3)
        response.status.should == 404
        json_response['message'].should == '404 Not Found'
      end

      it 'should fail if forked project exists in the user namespace' do
        post api("/projects/fork/#{project.id}", user)
        response.status.should == 409
        json_response['message']['base'].should == ['Invalid fork destination']
        json_response['message']['name'].should == ['has already been taken']
        json_response['message']['path'].should == ['has already been taken']
      end

      it 'should fail if project to fork from does not exist' do
        post api('/projects/fork/424242', user)
        response.status.should == 404
        json_response['message'].should == '404 Not Found'
      end
    end

    context 'when unauthenticated' do
      it 'should return authentication error' do
        post api("/projects/fork/#{project.id}")
        response.status.should == 401
        json_response['message'].should == '401 Unauthorized'
      end
    end
  end
end
