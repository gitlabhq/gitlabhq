require "spec_helper"

describe Files::UpdateService do
  subject { described_class.new(project, user, commit_params) }

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:new_contents) { "New Content" }
  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: "Update File",
      file_content: new_contents,
      file_content_encoding: "text",
      last_commit_sha: last_commit_sha,
      source_project: project,
      source_branch: project.default_branch,
      target_branch: project.default_branch,
    }
  end

  before do
    project.team << [user, :master]
  end

  describe "#execute" do
    context "when the file's last commit sha does not match the supplied last_commit_sha" do
      let(:last_commit_sha) { "foo" }

      it "returns a hash with the correct error message and a :error status " do
        expect { subject.execute }.
          to raise_error(Files::UpdateService::FileChangedError,
                         "You are attempting to update a file that has changed since you started editing it.")
      end
    end

    context "when the file's last commit sha does match the supplied last_commit_sha" do
      let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).sha }

      it "returns a hash with the :success status " do
        results = subject.execute

        expect(results).to match({ status: :success })
      end

      it "updates the file with the new contents" do
        subject.execute

        results = project.repository.blob_at_branch(project.default_branch, file_path)

        expect(results.data).to eq(new_contents)
      end
    end

    context "when the last_commit_sha is not supplied" do
      let(:commit_params) do
        {
          file_path: file_path,
          commit_message: "Update File",
          file_content: new_contents,
          file_content_encoding: "text",
          source_project: project,
          source_branch: project.default_branch,
          target_branch: project.default_branch,
        }
      end

      it "returns a hash with the :success status " do
        results = subject.execute

        expect(results).to match({ status: :success })
      end

      it "updates the file with the new contents" do
        subject.execute

        results = project.repository.blob_at_branch(project.default_branch, file_path)

        expect(results.data).to eq(new_contents)
      end
    end
  end
end
