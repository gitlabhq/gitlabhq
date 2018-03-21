require "spec_helper"

describe Files::CreateService do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:file_content) { 'Test file content' }
  let(:branch_name) { project.default_branch }
  let(:start_branch) { branch_name }

  let(:commit_params) do
    {
      file_path: file_path,
      commit_message: "Update File",
      file_content: file_content,
      file_content_encoding: "text",
      start_project: project,
      start_branch: start_branch,
      branch_name: branch_name
    }
  end

  subject { described_class.new(project, user, commit_params) }

  before do
    project.add_master(user)
  end

  describe "#execute" do
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
end
