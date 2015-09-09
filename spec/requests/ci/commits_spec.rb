require 'spec_helper'

describe "Commits" do
  before do
    @project = FactoryGirl.create :project
    @commit = FactoryGirl.create :commit, project: @project
  end

  describe "GET /:project/refs/:ref_name/commits/:id/status.json" do
    before do
      get status_project_ref_commit_path(@project, @commit.ref, @commit.sha), format: :json
    end

    it { response.status.should == 200 }
    it { response.body.should include(@commit.sha) }
  end
end
