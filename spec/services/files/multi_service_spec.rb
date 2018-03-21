require "spec_helper"

describe Files::MultiService do
  subject { described_class.new(project, user, commit_params) }

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:branch_name) { project.default_branch }
  let(:original_file_path) { 'files/ruby/popen.rb' }
  let(:new_file_path) { 'files/ruby/popen.rb' }
  let(:file_content) { 'New content' }
  let(:action) { 'update' }

  let!(:original_commit_id) do
    Gitlab::Git::Commit.last_for_path(project.repository, branch_name, original_file_path).sha
  end

  let(:default_action) do
    {
      action: action,
      file_path: new_file_path,
      previous_path: original_file_path,
      content: file_content,
      last_commit_id: original_commit_id
    }
  end

  let(:actions) { [default_action] }

  let(:commit_params) do
    {
      commit_message: "Update File",
      branch_name: branch_name,
      start_branch: branch_name,
      actions: actions
    }
  end

  before do
    project.add_master(user)
  end

  describe '#execute' do
    context 'with a valid action' do
      it 'returns a hash with the :success status' do
        results = subject.execute

        expect(results[:status]).to eq(:success)
      end
    end

    context 'with an invalid action' do
      let(:action) { 'rename' }

      it 'returns a hash with the :error status' do
        results = subject.execute

        expect(results[:status]).to eq(:error)
        expect(results[:message]).to match(/Unknown action/)
      end
    end

    describe 'Updating files' do
      context 'when the file has been previously updated' do
        before do
          update_file(original_file_path)
        end

        it 'rejects the commit' do
          results = subject.execute

          expect(results[:status]).to eq(:error)
          expect(results[:message]).to match(new_file_path)
        end
      end

      context 'when the file have not been modified' do
        it 'accepts the commit' do
          results = subject.execute

          expect(results[:status]).to eq(:success)
        end
      end
    end

    context 'when moving a file' do
      let(:action) { 'move' }
      let(:new_file_path) { 'files/ruby/new_popen.rb' }

      context 'when original file has been updated' do
        before do
          update_file(original_file_path)
        end

        it 'rejects the commit' do
          results = subject.execute

          expect(results[:status]).to eq(:error)
          expect(results[:message]).to match(original_file_path)
        end
      end

      context 'when original file have not been updated' do
        it 'moves the file' do
          results = subject.execute
          blob = project.repository.blob_at_branch(branch_name, new_file_path)

          expect(results[:status]).to eq(:success)
          expect(blob).to be_present
        end
      end
    end

    context 'when creating a file matching an LFS filter' do
      let(:action) { 'create' }
      let(:branch_name) { 'lfs' }
      let(:new_file_path) { 'test_file.lfs' }

      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      it 'creates an LFS pointer' do
        subject.execute

        blob = repository.blob_at('lfs', new_file_path)

        expect(blob.data).to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
      end

      it "creates an LfsObject with the file's content" do
        subject.execute

        expect(LfsObject.last.file.read).to eq file_content
      end

      context 'with base64 encoded content' do
        let(:raw_file_content) { 'Raw content' }
        let(:file_content) { Base64.encode64(raw_file_content) }
        let(:actions) { [default_action.merge(encoding: 'base64')] }

        it 'creates an LFS pointer' do
          subject.execute

          blob = repository.blob_at('lfs', new_file_path)

          expect(blob.data).to start_with(Gitlab::Git::LfsPointerFile::VERSION_LINE)
        end

        it "creates an LfsObject with the file's content" do
          subject.execute

          expect(LfsObject.last.file.read).to eq raw_file_content
        end
      end

      it 'links the LfsObject to the project' do
        expect do
          subject.execute
        end.to change { project.lfs_objects.count }.by(1)
      end
    end

    context 'when file status validation is skipped' do
      let(:action) { 'create' }
      let(:new_file_path) { 'files/ruby/new_file.rb' }

      it 'does not check the last commit' do
        expect(Gitlab::Git::Commit).not_to receive(:last_for_path)

        subject.execute
      end

      it 'creates the file' do
        subject.execute

        blob = project.repository.blob_at_branch(branch_name, new_file_path)

        expect(blob).to be_present
      end
    end
  end

  def update_file(path)
    params = {
      file_path: path,
      start_branch: branch_name,
      branch_name: branch_name,
      commit_message: 'Update file',
      file_content: 'New content'
    }

    Files::UpdateService.new(project, user, params).execute
  end
end
