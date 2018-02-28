require "spec_helper"

describe Files::UpdateService do
  subject { described_class.new(project, user, commit_params) }

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:new_contents) { 'New Content' }
  let(:branch_name) { project.default_branch }
  let(:last_commit_sha) { nil }

  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: "Update File",
      file_content: new_contents,
      file_content_encoding: "text",
      last_commit_sha: last_commit_sha,
      start_project: project,
      start_branch: project.default_branch,
      branch_name: branch_name
    }
  end

  before do
    project.add_master(user)
  end

  describe "#execute" do
    context "when the file's last commit sha does not match the supplied last_commit_sha" do
      let(:last_commit_sha) { "foo" }

      it "returns a hash with the correct error message and a :error status " do
        expect { subject.execute }
          .to raise_error(Files::UpdateService::FileChangedError,
                         "You are attempting to update a file that has changed since you started editing it.")
      end
    end

    context "when the file's last commit sha does match the supplied last_commit_sha" do
      let(:last_commit_sha) { Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, file_path).sha }

      it "returns a hash with the :success status " do
        results = subject.execute

        expect(results[:status]).to match(:success)
      end

      it "updates the file with the new contents" do
        subject.execute

        results = project.repository.blob_at_branch(project.default_branch, file_path)

        expect(results.data).to eq(new_contents)
      end
    end

    context "when the last_commit_sha is not supplied" do
      it "returns a hash with the :success status " do
        results = subject.execute

        expect(results[:status]).to match(:success)
      end

      it "updates the file with the new contents" do
        subject.execute

        results = project.repository.blob_at_branch(project.default_branch, file_path)

        expect(results.data).to eq(new_contents)
      end
    end

    context 'with gitaly disabled', :skip_gitaly_mock do
      context 'when target branch is different than source branch' do
        let(:branch_name) { "#{project.default_branch}-new" }

        it 'fires hooks only once' do
          expect(Gitlab::Git::HooksService).to receive(:new).once.and_call_original

          subject.execute
        end
      end
    end
  end
end
