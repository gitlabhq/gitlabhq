# frozen_string_literal: true

require "spec_helper"

RSpec.describe Files::DeleteService, feature_category: :source_code_management do
  subject { described_class.new(project, user, commit_params) }

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, :commit_email) }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:branch_name) { project.default_branch }
  let(:last_commit_sha) { nil }
  let(:commit) { project.repository.head_commit }

  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: "Delete File",
      last_commit_sha: last_commit_sha,
      start_project: project,
      start_branch: project.default_branch,
      branch_name: branch_name
    }
  end

  shared_examples 'successfully deletes the file' do
    it 'returns a hash with the :success status' do
      results = subject.execute

      expect(results[:status]).to match(:success)
    end

    it 'deletes the file' do
      subject.execute

      blob = project.repository.blob_at_branch(project.default_branch, file_path)

      expect(blob).to be_nil
    end

    it 'uses the commit email' do
      subject.execute

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(user.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
    end
  end

  before do
    project.add_maintainer(user)
  end

  describe "#execute" do
    context "when the file's last commit is earlier than the latest commit for this branch" do
      let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).parent_id }

      it "returns a hash with the correct error message and a :error status" do
        expect { subject.execute }.to raise_error(
          Files::UpdateService::FileChangedError,
          "You are attempting to delete a file that has been previously updated."
        )
      end
    end

    context "when the file's last commit sha does match the supplied last_commit_sha" do
      let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).sha }

      it_behaves_like 'successfully deletes the file'
    end

    context "when the last_commit_sha is not supplied" do
      it_behaves_like 'successfully deletes the file'
    end
  end
end
