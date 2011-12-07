require 'spec_helper'

describe "Projects" do
  describe "GET /projects" do
    it { projects_path.should be_allowed_for :admin }
    it { projects_path.should be_allowed_for :user }
    it { projects_path.should be_denied_for :visitor }
  end

  describe "GET /projects/new" do
    it { projects_path.should be_allowed_for :admin }
    it { projects_path.should be_allowed_for :user }
    it { projects_path.should be_denied_for :visitor }
  end

  describe "Project" do
    before do
      @project = Factory :project
      @u1 = Factory :user
      @u2 = Factory :user
      @u3 = Factory :user
      # full access
      @project.users_projects.create(:user => @u1, :project_access => Project::PROJECT_RWA)
      # no access
      @project.users_projects.create(:user => @u2, :project_access => Project::PROJECT_N)
      # readonly
      @project.users_projects.create(:user => @u3, :project_access => Project::PROJECT_R)
    end

    describe "GET /project_code" do
      it { project_path(@project).should be_allowed_for @u1 }
      it { project_path(@project).should be_allowed_for @u3 }
      it { project_path(@project).should be_denied_for :admin }
      it { project_path(@project).should be_denied_for @u2 }
      it { project_path(@project).should be_denied_for :user }
      it { project_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/master/tree" do
      it { tree_project_ref_path(@project, @project.root_ref).should be_allowed_for @u1 }
      it { tree_project_ref_path(@project, @project.root_ref).should be_allowed_for @u3 }
      it { tree_project_ref_path(@project, @project.root_ref).should be_denied_for :admin }
      it { tree_project_ref_path(@project, @project.root_ref).should be_denied_for @u2 }
      it { tree_project_ref_path(@project, @project.root_ref).should be_denied_for :user }
      it { tree_project_ref_path(@project, @project.root_ref).should be_denied_for :visitor }
    end

    describe "GET /project_code/commits" do
      it { project_commits_path(@project).should be_allowed_for @u1 }
      it { project_commits_path(@project).should be_allowed_for @u3 }
      it { project_commits_path(@project).should be_denied_for :admin }
      it { project_commits_path(@project).should be_denied_for @u2 }
      it { project_commits_path(@project).should be_denied_for :user }
      it { project_commits_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/commit" do
      it { project_commit_path(@project, @project.commit.id).should be_allowed_for @u1 }
      it { project_commit_path(@project, @project.commit.id).should be_allowed_for @u3 }
      it { project_commit_path(@project, @project.commit.id).should be_denied_for :admin }
      it { project_commit_path(@project, @project.commit.id).should be_denied_for @u2 }
      it { project_commit_path(@project, @project.commit.id).should be_denied_for :user }
      it { project_commit_path(@project, @project.commit.id).should be_denied_for :visitor }
    end

    describe "GET /project_code/team" do
      it { team_project_path(@project).should be_allowed_for @u1 }
      it { team_project_path(@project).should be_allowed_for @u3 }
      it { team_project_path(@project).should be_denied_for :admin }
      it { team_project_path(@project).should be_denied_for @u2 }
      it { team_project_path(@project).should be_denied_for :user }
      it { team_project_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/wall" do
      it { wall_project_path(@project).should be_allowed_for @u1 }
      it { wall_project_path(@project).should be_allowed_for @u3 }
      it { wall_project_path(@project).should be_denied_for :admin }
      it { wall_project_path(@project).should be_denied_for @u2 }
      it { wall_project_path(@project).should be_denied_for :user }
      it { wall_project_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/blob" do
      before do
        @commit = @project.commit
        @path = @commit.tree.contents.select { |i| i.is_a?(Grit::Blob)}.first.name
        @blob_path = blob_project_ref_path(@project, @commit.id, :path => @path)
      end

      it { @blob_path.should be_allowed_for @u1 }
      it { @blob_path.should be_allowed_for @u3 }
      it { @blob_path.should be_denied_for :admin }
      it { @blob_path.should be_denied_for @u2 }
      it { @blob_path.should be_denied_for :user }
      it { @blob_path.should be_denied_for :visitor }
    end

    describe "GET /project_code/edit" do
      it { edit_project_path(@project).should be_allowed_for @u1 }
      it { edit_project_path(@project).should be_denied_for @u3 }
      it { edit_project_path(@project).should be_denied_for :admin }
      it { edit_project_path(@project).should be_denied_for @u2 }
      it { edit_project_path(@project).should be_denied_for :user }
      it { edit_project_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/issues" do
      it { project_issues_path(@project).should be_allowed_for @u1 }
      it { project_issues_path(@project).should be_allowed_for @u3 }
      it { project_issues_path(@project).should be_denied_for :admin }
      it { project_issues_path(@project).should be_denied_for @u2 }
      it { project_issues_path(@project).should be_denied_for :user }
      it { project_issues_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/snippets" do
      it { project_snippets_path(@project).should be_allowed_for @u1 }
      it { project_snippets_path(@project).should be_allowed_for @u3 }
      it { project_snippets_path(@project).should be_denied_for :admin }
      it { project_snippets_path(@project).should be_denied_for @u2 }
      it { project_snippets_path(@project).should be_denied_for :user }
      it { project_snippets_path(@project).should be_denied_for :visitor }
    end

    describe "GET /project_code/merge_requests" do
      it { project_merge_requests_path(@project).should be_allowed_for @u1 }
      it { project_merge_requests_path(@project).should be_allowed_for @u3 }
      it { project_merge_requests_path(@project).should be_denied_for :admin }
      it { project_merge_requests_path(@project).should be_denied_for @u2 }
      it { project_merge_requests_path(@project).should be_denied_for :user }
      it { project_merge_requests_path(@project).should be_denied_for :visitor }
    end
  end
end
