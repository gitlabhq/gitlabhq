# frozen_string_literal: true

require "spec_helper"

RSpec.describe Files::UpdateService, feature_category: :source_code_management do
  subject(:update_service) { described_class.new(project, user, commit_params) }

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, :commit_email) }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:new_contents) { 'New Content' }
  let(:branch_name) { project.default_branch }
  let(:start_branch) { project.default_branch }
  let(:last_commit_sha) { nil }
  let(:commit) { project.repository.commit }

  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: "Update File",
      file_content: new_contents,
      file_content_encoding: "text",
      last_commit_sha: last_commit_sha,
      start_project: project,
      start_branch: start_branch,
      branch_name: branch_name
    }
  end

  before do
    project.add_maintainer(user)
  end

  describe "#execute" do
    let(:lfs_enabled) { nil }

    before do
      allow(project).to receive(:lfs_enabled?).and_return(lfs_enabled)
    end

    context 'with LFS disabled' do
      let(:lfs_enabled) { false }

      context "when the file's last commit sha is earlier than the latest change for that branch" do
        let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).parent_id }

        it "returns a hash with the correct error message and a :error status" do
          expect { update_service.execute }
            .to raise_error(
              Files::UpdateService::FileChangedError,
              "You are attempting to update a file that has changed since you started editing it."
            )
        end
      end

      context "when the file's last commit sha does match the supplied last_commit_sha" do
        let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).sha }

        it "returns a hash with the :success status" do
          results = update_service.execute

          expect(results[:status]).to match(:success)
        end

        it "updates the file with the new contents" do
          update_service.execute

          results = project.repository.blob_at_branch(project.default_branch, file_path)

          expect(results.data).to eq(new_contents)
        end

        it 'uses the commit email' do
          update_service.execute

          expect(user.commit_email).not_to eq(user.email)
          expect(commit.author_email).to eq(user.commit_email)
          expect(commit.committer_email).to eq(user.commit_email)
        end
      end

      context "when the last_commit_sha is not supplied" do
        it "returns a hash with the :success status" do
          results = update_service.execute

          expect(results[:status]).to match(:success)
        end

        it "updates the file with the new contents" do
          update_service.execute

          results = project.repository.blob_at_branch(project.default_branch, file_path)

          expect(results.data).to eq(new_contents)
        end
      end
    end

    context 'with LFS enabled' do
      let(:lfs_enabled) { true }
      let(:branch_name) { 'png-lfs' }
      let(:start_branch) { 'png-lfs' }
      let(:file_path) { 'files/images/emoji.png' }
      let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, branch_name, file_path).sha }

      it 'creates an LFS pointer' do
        update_service.execute

        blob = project.repository.blob_at(branch_name, file_path)

        expect(blob.data).to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
      end
    end
  end
end
