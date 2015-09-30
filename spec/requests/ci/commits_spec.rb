require 'spec_helper'

describe "Commits" do
  before do
    @commit = FactoryGirl.create :ci_commit
  end

  describe "GET /:project/refs/:ref_name/commits/:id/status.json" do
    before do
      get status_ci_project_ref_commits_path(@commit.project, @commit.ref, @commit.sha), format: :json
    end

    it { expect(response.status).to eq(200) }
    it { expect(response.body).to include(@commit.sha) }
  end
end
