require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:label1) { create(:label, title: 'label1', project: project) }

  before do
    project.team << [user, :master]
  end


  describe 'GET /projects/:id/labels' do
    it 'should return project labels' do
      get api("/projects/#{project.id}/labels", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.size.should == 1
      json_response.first['name'].should == label1.name
    end
  end

  describe 'POST /projects/:id/labels' do
    it 'should return created label' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAABB'
      response.status.should == 201
      json_response['name'].should == 'Foo'
      json_response['color'].should == '#FFAABB'
    end

    it 'should return a 400 bad request if name not given' do
      post api("/projects/#{project.id}/labels", user), color: '#FFAABB'
      response.status.should == 400
    end

    it 'should return a 400 bad request if color not given' do
      post api("/projects/#{project.id}/labels", user), name: 'Foobar'
      response.status.should == 400
    end

    it 'should return 400 for invalid color' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAA'
      response.status.should == 400
      json_response['message'].should == 'Color is invalid'
    end

    it 'should return 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      response.status.should == 400
      json_response['message'].should == 'Color is invalid'
    end

    it 'should return 400 for invalid name' do
      post api("/projects/#{project.id}/labels", user),
           name: '?',
           color: '#FFAABB'
      response.status.should == 400
      json_response['message'].should == 'Title is invalid'
    end

    it 'should return 409 if label already exists' do
      post api("/projects/#{project.id}/labels", user),
           name: 'label1',
           color: '#FFAABB'
      response.status.should == 409
      json_response['message'].should == 'Label already exists'
    end
  end

  describe 'DELETE /projects/:id/labels' do
    it 'should return 200 for existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label1'
      response.status.should == 200
    end

    it 'should return 404 for non existing label' do
      delete api("/projects/#{project.id}/labels", user), name: 'label2'
      response.status.should == 404
      json_response['message'].should == 'Label not found'
    end

    it 'should return 400 for wrong parameters' do
      delete api("/projects/#{project.id}/labels", user)
      response.status.should == 400
    end
  end

  describe 'PUT /projects/:id/labels' do
    it 'should return 200 if name and colors are changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label',
          color: '#FFFFFF'
      response.status.should == 200
      json_response['name'].should == 'New Label'
      json_response['color'].should == '#FFFFFF'
    end

    it 'should return 200 if name is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: 'New Label'
      response.status.should == 200
      json_response['name'].should == 'New Label'
      json_response['color'].should == label1.color
    end

    it 'should return 200 if colors is changed' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FFFFFF'
      response.status.should == 200
      json_response['name'].should == label1.name
      json_response['color'].should == '#FFFFFF'
    end

    it 'should return 404 if label does not exist' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label2',
          new_name: 'label3'
      response.status.should == 404
    end

    it 'should return 400 if no label name given' do
      put api("/projects/#{project.id}/labels", user), new_name: 'label2'
      response.status.should == 400
    end

    it 'should return 400 if no new parameters given' do
      put api("/projects/#{project.id}/labels", user), name: 'label1'
      response.status.should == 400
    end

    it 'should return 400 for invalid name' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          new_name: '?',
          color: '#FFFFFF'
      response.status.should == 400
      json_response['message'].should == 'Title is invalid'
    end

    it 'should return 400 for invalid name' do
      put api("/projects/#{project.id}/labels", user),
          name: 'label1',
          color: '#FF'
      response.status.should == 400
      json_response['message'].should == 'Color is invalid'
    end

    it 'should return 400 for too long color code' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAAFFFF'
      response.status.should == 400
      json_response['message'].should == 'Color is invalid'
    end
  end
end
