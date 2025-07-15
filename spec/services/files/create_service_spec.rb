# frozen_string_literal: true

require "spec_helper"

RSpec.describe Files::CreateService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user, :commit_email) }
  let(:file_content) { 'Test file content' }
  let(:branch_name) { project.default_branch }
  let(:commit_message) { 'Update File' }
  let(:start_branch) { branch_name }
  let(:file_path) { 'some.file' }

  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: commit_message,
      file_content: file_content,
      file_content_encoding: "text",
      start_project: project,
      start_branch: start_branch,
      branch_name: branch_name
    }
  end

  let(:commit) { repository.head_commit }

  subject { described_class.new(project, user, commit_params) }

  before do
    project.add_maintainer(user)
  end

  describe "#execute" do
    context 'when commit message is missing' do
      let(:commit_message) { nil }

      it 'returns an error' do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('You must provide a commit message')
      end
    end

    context 'when file matches LFS filter' do
      let(:file_path) { 'test_file.lfs' }
      let(:branch_name) { 'lfs' }

      context 'with LFS disabled' do
        it 'skips gitattributes check' do
          expect(repository).not_to receive(:attributes_at)

          subject.execute
        end

        it "doesn't create LFS pointers" do
          subject.execute

          blob = repository.blob_at('lfs', file_path)

          expect(blob.data).not_to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
          expect(blob.data).to eq(file_content)
        end
      end

      context 'with LFS enabled' do
        before do
          allow(project).to receive(:lfs_enabled?).and_return(true)
        end

        it 'creates an LFS pointer' do
          subject.execute

          blob = repository.blob_at('lfs', file_path)

          expect(blob.data).to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
        end

        it "creates an LfsObject with the file's content" do
          subject.execute

          expect(LfsObject.last.file.read).to eq file_content
        end

        it 'links the LfsObject to the project' do
          expect do
            subject.execute
          end.to change { project.lfs_objects.count }.by(1)
        end
      end
    end
  end

  context 'commit attribute' do
    let(:file_path) { 'test-commit-attributes.txt' }

    it 'uses the commit email' do
      subject.execute

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(user.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
    end
  end
end
