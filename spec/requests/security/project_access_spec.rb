require 'spec_helper'

describe "Application access" do
  describe "GET /" do
    it { root_path.should be_allowed_for :admin }
    it { root_path.should be_allowed_for :user }
    it { root_path.should be_denied_for :visitor }
  end

  describe "GET /projects/new" do
    it { new_project_path.should be_allowed_for :admin }
    it { new_project_path.should be_allowed_for :user }
    it { new_project_path.should be_denied_for :visitor }
  end

  describe "Project" do
    before do
      @project = Factory :project
      @u1 = Factory :user
      @u2 = Factory :user
      @u3 = Factory :user
      # full access
      @project.users_projects.create(user: @u1, project_access: UsersProject::MASTER)
      # readonly
      @project.users_projects.create(user: @u3, project_access: UsersProject::REPORTER)
    end

    describe "GET /project_code" do
      subject { project_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/master/tree" do
      subject { tree_project_ref_path(@project, @project.root_ref) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/commits" do
      subject { project_commits_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/commit" do
      subject { project_commit_path(@project, @project.commit.id) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/team" do
      subject { team_project_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/wall" do
      subject { wall_project_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/blob" do
      before do
        commit = @project.commit
        path = commit.tree.contents.select { |i| i.is_a?(Grit::Blob)}.first.name
        @blob_path = blob_project_ref_path(@project, commit.id, path: path)
      end

      it { @blob_path.should be_allowed_for @u1 }
      it { @blob_path.should be_allowed_for @u3 }
      it { @blob_path.should be_denied_for :admin }
      it { @blob_path.should be_denied_for @u2 }
      it { @blob_path.should be_denied_for :user }
      it { @blob_path.should be_denied_for :visitor }
    end

    describe "GET /project_code/edit" do
      subject { edit_project_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_denied_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/deploy_keys" do
      subject { project_deploy_keys_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_denied_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/issues" do
      subject { project_issues_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/snippets" do
      subject { project_snippets_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/merge_requests" do
      subject { project_merge_requests_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository" do
      subject { project_repository_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository/branches" do
      subject { branches_project_repository_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository/tags" do
      subject { tags_project_repository_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/hooks" do
      subject { project_hooks_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/files" do
      subject { files_project_path(@project) }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for @u3 }
      it { should be_denied_for :admin }
      it { should be_denied_for @u2 }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end
  end
end
