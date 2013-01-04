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
    let(:project)  { create(:project) }

    let(:master)   { create(:user) }
    let(:guest)    { create(:user) }
    let(:reporter) { create(:user) }

    before do
      # full access
      project.team << [master, :master]

      # readonly
      project.team << [reporter, :reporter]
    end

    describe "GET /project_code" do
      subject { project_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/tree/master" do
      subject { project_tree_path(project, project.repository.root_ref) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/commits/master" do
      subject { project_commits_path(project, project.repository.root_ref, limit: 1) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/commit/:sha" do
      subject { project_commit_path(project, project.repository.commit) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/compare" do
      subject { project_compare_index_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/team" do
      subject { project_team_index_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/wall" do
      subject { wall_project_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/blob" do
      before do
        commit = project.repository.commit
        path = commit.tree.contents.select { |i| i.is_a?(Grit::Blob)}.first.name
        @blob_path = project_blob_path(project, File.join(commit.id, path))
      end

      it { @blob_path.should be_allowed_for master }
      it { @blob_path.should be_allowed_for reporter }
      it { @blob_path.should be_denied_for :admin }
      it { @blob_path.should be_denied_for guest }
      it { @blob_path.should be_denied_for :user }
      it { @blob_path.should be_denied_for :visitor }
    end

    describe "GET /project_code/edit" do
      subject { edit_project_path(project) }

      it { should be_allowed_for master }
      it { should be_denied_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/deploy_keys" do
      subject { project_deploy_keys_path(project) }

      it { should be_allowed_for master }
      it { should be_denied_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/issues" do
      subject { project_issues_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/snippets" do
      subject { project_snippets_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/merge_requests" do
      subject { project_merge_requests_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository" do
      subject { project_repository_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository/branches" do
      subject { branches_project_repository_path(project) }

      before do
        # Speed increase
        Project.any_instance.stub(:branches).and_return([])
      end

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/repository/tags" do
      subject { tags_project_repository_path(project) }

      before do
        # Speed increase
        Project.any_instance.stub(:tags).and_return([])
      end

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/hooks" do
      subject { project_hooks_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /project_code/files" do
      subject { files_project_path(project) }

      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_denied_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end
  end
end
