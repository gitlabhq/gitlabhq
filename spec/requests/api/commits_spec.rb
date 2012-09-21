require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { Factory :user }
  let!(:project) { Factory :project, owner: user }

  describe "GET /projects/:id/commits" do
    context "authorized user" do
      before { project.add_access(user, :read) }

      it "should return project commits" do
        get api("/projects/#{project.code}/commits", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['id'].should == project.commit.id
      end
    end

    context "unauthorized user" do
      it "should return project commits" do
        get api("/projects/#{project.code}/commits")
        response.status.should == 401
      end
    end
  end
end
