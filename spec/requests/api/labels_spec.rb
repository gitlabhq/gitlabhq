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
end
