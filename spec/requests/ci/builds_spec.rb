require 'spec_helper'

describe "Builds" do
  before do
    @project = FactoryGirl.create :project
    @commit = FactoryGirl.create :commit, project: @project
    @build = FactoryGirl.create :build, commit: @commit
  end

  describe "GET /:project/builds/:id/status.json" do
    before do
      get status_project_build_path(@project, @build), format: :json
    end

    it { response.status.should == 200 }
    it { response.body.should include(@build.sha) }
  end
end
