# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetRepository, feature_category: :snippets do
  let_it_be(:user) { create(:user) }

  let(:snippet) { create(:personal_snippet, :repository, author: user) }
  let(:snippet_repository) { snippet.snippet_repository }
  let(:commit_opts) { { branch_name: 'master', message: 'whatever' } }

  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:snippet) }
  end

  it_behaves_like 'shardable scopes' do
    let_it_be(:record_1) { create(:snippet_repository) }
    let_it_be(:record_2, reload: true) { create(:snippet_repository) }
  end

  describe '.find_snippet' do
    it 'finds snippet by disk path' do
      snippet = create(:project_snippet, author: user)
      snippet.track_snippet_repository(snippet.repository.storage)

      expect(described_class.find_snippet(snippet.disk_path)).to eq(snippet)
    end

    it 'returns nil when it does not find the snippet' do
      expect(described_class.find_snippet('@@unexisting/path/to/snippet')).to be_nil
    end
  end

  describe '#multi_files_action' do
    let(:new_file) { { file_path: 'new_file_test', content: 'bar' } }
    let(:move_file) { { previous_path: 'CHANGELOG', file_path: 'CHANGELOG_new', content: 'bar' } }
    let(:update_file) { { previous_path: 'README', file_path: 'README', content: 'bar' } }
    let(:data) { [new_file, move_file, update_file] }

    let_it_be(:unnamed_snippet) { { file_path: '', content: 'dummy', action: :create } }
    let_it_be(:named_snippet) { { file_path: 'fee.txt', content: 'bar', action: :create } }

    it 'returns nil when files argument is empty' do
      expect(snippet.repository).not_to receive(:commit_files)

      operation = snippet_repository.multi_files_action(user, [], **commit_opts)

      expect(operation).to be_nil
    end

    it 'returns nil when files argument is nil' do
      expect(snippet.repository).not_to receive(:commit_files)

      operation = snippet_repository.multi_files_action(user, nil, **commit_opts)

      expect(operation).to be_nil
    end

    it 'performs the operation accordingly to the files data' do
      new_file_blob = blob_at(snippet, new_file[:file_path])
      move_file_blob = blob_at(snippet, move_file[:previous_path])
      update_file_blob = blob_at(snippet, update_file[:previous_path])

      aggregate_failures do
        expect(new_file_blob).to be_nil
        expect(move_file_blob).not_to be_nil
        expect(update_file_blob).not_to be_nil
      end

      expect(described_class.sticking).to receive(:stick)

      expect do
        snippet_repository.multi_files_action(user, data, **commit_opts)
      end.not_to raise_error

      aggregate_failures do
        data.each do |entry|
          blob = blob_at(snippet, entry[:file_path])

          expect(blob).not_to be_nil
          expect(blob.path).to eq entry[:file_path]
          expect(blob.data).to eq entry[:content]
        end
      end
    end

    it 'tries to obtain an exclusive lease' do
      expect(Gitlab::ExclusiveLease).to receive(:new).with("multi_files_action:#{snippet.id}", anything).and_call_original

      snippet_repository.multi_files_action(user, data, **commit_opts)
    end

    it 'cancels the lease when the method has finished' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).with("multi_files_action:#{snippet.id}", anything).and_call_original

      snippet_repository.multi_files_action(user, data, **commit_opts)
    end

    it 'raises an error if the lease cannot be obtained' do
      allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
        allow(instance).to receive(:try_obtain).and_return false
      end

      expect do
        snippet_repository.multi_files_action(user, data, **commit_opts)
      end.to raise_error(described_class::CommitError)
    end

    context 'with commit actions' do
      let(:result) do
        [{ action: :create }.merge(new_file),
         { action: :move }.merge(move_file),
         { action: :update }.merge(update_file)]
      end

      let(:repo) { double }

      before do
        allow(snippet).to receive(:repository).and_return(repo)
        allow(repo).to receive(:ls_files).and_return([])
        allow(repo).to receive(:root_ref).and_return('master')
        allow(repo).to receive(:empty?).and_return(false)
      end

      it 'infers the commit action based on the parameters if not present' do
        expect(repo).to receive(:commit_files).with(user, hash_including(actions: result))

        snippet_repository.multi_files_action(user, data, **commit_opts)
      end

      context 'when commit actions are present' do
        shared_examples 'uses the expected action' do |action, expected_action|
          let(:file_action) { { file_path: 'foo.txt', content: 'foo', action: action } }
          let(:data) { [file_action] }

          specify do
            expect(repo).to(
              receive(:commit_files).with(
                user,
                hash_including(actions: array_including(hash_including(action: expected_action)))))

            snippet_repository.multi_files_action(user, data, **commit_opts)
          end
        end

        it_behaves_like 'uses the expected action', :foobar, :foobar

        context 'when action is a string' do
          it_behaves_like 'uses the expected action', 'foobar', :foobar
        end
      end
    end

    context 'when move action does not include content' do
      let(:previous_path) { 'CHANGELOG' }
      let(:new_path) { 'CHANGELOG_new' }
      let(:move_action) { { previous_path: previous_path, file_path: new_path, action: action } }

      shared_examples 'renames file and does not update content' do
        specify do
          existing_content = blob_at(snippet, previous_path).data

          snippet_repository.multi_files_action(user, [move_action], **commit_opts)

          blob = blob_at(snippet, new_path)
          expect(blob).not_to be_nil
          expect(blob.data).to eq existing_content
        end
      end

      context 'when action is not set' do
        let(:action) { nil }

        it_behaves_like 'renames file and does not update content'
      end

      context 'when action is set' do
        let(:action) { :move }

        it_behaves_like 'renames file and does not update content'
      end
    end

    context 'when update action does not include content' do
      let(:update_action) { { previous_path: 'CHANGELOG', file_path: 'CHANGELOG', action: action } }

      shared_examples 'does not commit anything' do
        specify do
          last_commit_id = snippet.repository.head_commit.id

          snippet_repository.multi_files_action(user, [update_action], **commit_opts)

          expect(snippet.repository.head_commit.id).to eq last_commit_id
        end
      end

      context 'when action is not set' do
        let(:action) { nil }

        it_behaves_like 'does not commit anything'
      end

      context 'when action is set' do
        let(:action) { :update }

        it_behaves_like 'does not commit anything'
      end
    end

    shared_examples 'snippet repository with file names' do |*filenames|
      it 'sets a name for unnamed files' do
        ls_files = snippet.repository.ls_files(snippet.default_branch)
        expect(ls_files).to include(*filenames)
      end
    end

    context 'when existing file has a default name' do
      let(:default_name) { 'snippetfile1.txt' }
      let(:new_file) { { file_path: '', content: 'bar' } }
      let(:existing_file) { { previous_path: default_name, file_path: '', content: 'new_content' } }

      before do
        expect(blob_at(snippet, default_name)).to be_nil

        snippet_repository.multi_files_action(user, [new_file], **commit_opts)

        expect(blob_at(snippet, default_name)).to be_present
      end

      it 'reuses the existing file name' do
        snippet_repository.multi_files_action(user, [existing_file], **commit_opts)

        blob = blob_at(snippet, default_name)
        expect(blob.data).to eq existing_file[:content]
      end
    end

    context 'when file name consists of one or several whitespaces' do
      let(:default_name) { 'snippetfile1.txt' }
      let(:new_file) { { file_path: ' ', content: 'bar' } }

      it 'assigns a new name to the file' do
        expect(blob_at(snippet, default_name)).to be_nil

        snippet_repository.multi_files_action(user, [new_file], **commit_opts)

        blob = blob_at(snippet, default_name)
        expect(blob.data).to eq new_file[:content]
      end
    end

    context 'when some files are not named' do
      let(:data) { [named_snippet] + Array.new(2) { unnamed_snippet.clone } }

      before do
        expect do
          snippet_repository.multi_files_action(user, data, **commit_opts)
        end.not_to raise_error
      end

      it_behaves_like 'snippet repository with file names', 'snippetfile1.txt', 'snippetfile2.txt'
    end

    context 'repository already has 10 unnamed snippets' do
      let(:pre_populate_data) { Array.new(10) { unnamed_snippet.clone } }
      let(:data) { [named_snippet] + Array.new(2) { unnamed_snippet.clone } }

      before do
        # Pre-populate repository with 9 unnamed snippets.
        snippet_repository.multi_files_action(user, pre_populate_data, **commit_opts)

        expect do
          snippet_repository.multi_files_action(user, data, **commit_opts)
        end.not_to raise_error
      end

      it_behaves_like 'snippet repository with file names', 'snippetfile10.txt', 'snippetfile11.txt'
    end

    shared_examples 'snippet repository with git errors' do |path, error|
      let(:new_file) { { file_path: path, content: 'bar' } }

      it 'raises a path specific error' do
        expect do
          snippet_repository.multi_files_action(user, data, **commit_opts)
        end.to raise_error(error)
      end
    end

    context 'with git errors' do
      it_behaves_like 'snippet repository with git errors', 'invalid://path/here', described_class::InvalidPathError
      it_behaves_like 'snippet repository with git errors', '.git/hooks/pre-commit', described_class::InvalidPathError
      it_behaves_like 'snippet repository with git errors', '../../path/traversal/here', described_class::InvalidPathError
      it_behaves_like 'snippet repository with git errors', 'README', described_class::CommitError

      context 'when user name is invalid' do
        let(:user) { create(:user, name: ',') }

        it_behaves_like 'snippet repository with git errors', 'non_existing_file', described_class::InvalidSignatureError
      end

      context 'when user email is empty' do
        let(:user) { create(:user) }

        before do
          user.update_column(:email, '')
        end

        it_behaves_like 'snippet repository with git errors', 'non_existing_file', described_class::InvalidSignatureError
      end
    end
  end

  def blob_at(snippet, path)
    snippet.repository.blob_at('master', path)
  end

  def first_blob(snippet)
    snippet.repository.blob_at('master', snippet.repository.ls_files(snippet.default_branch).first)
  end
end
