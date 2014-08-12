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

    it 'should return 405 for invalid color' do
      post api("/projects/#{project.id}/labels", user),
           name: 'Foo',
           color: '#FFAA'
      response.status.should == 405
      json_response['message'].should == 'Color is invalid'
    end

    it 'should return 405 for invalid name' do
      post api("/projects/#{project.id}/labels", user),
           name: '?',
           color: '#FFAABB'
      response.status.should == 405
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
      delete api("/projects/#{project.id}/labels", user),
             name: 'label1'
      response.status.should == 200
    end

    it 'should return 404 for non existing label' do
      delete api("/projects/#{project.id}/labels", user),
             name: 'label2'
      response.status.should == 404
      json_response['message'].should == 'Label not found'
    end

    it 'should return 400 for wrong parameters' do
      delete api("/projects/#{project.id}/labels", user)
      response.status.should == 400
    end
  end
end
