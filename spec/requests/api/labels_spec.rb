require 'spec_helper'

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:issue) { create(:issue, author: user, assignee: user, project: project, :label_list => "label1, label2") }
  before { project.team << [user, :reporter] }


  describe "GET /projects/:id/labels" do
    it "should return project labels" do
      get api("/projects/#{project.id}/labels", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == 'label1'
      json_response.last['name'].should == 'label2'
    end
  end


end

