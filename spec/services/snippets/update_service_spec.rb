# frozen_string_literal: true

require 'spec_helper'

describe Snippets::UpdateService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create :user, admin: true }
    let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
    let(:base_opts) do
      {
        title: 'Test snippet',
        file_name: 'snippet.rb',
        content: 'puts "hello world"',
        visibility_level: visibility_level
      }
    end
    let(:extra_opts) { {} }
    let(:options) { base_opts.merge(extra_opts) }
    let(:updater) { user }
    let(:service) { Snippets::UpdateService.new(project, updater, options) }

    subject { service.execute(snippet) }

    shared_examples 'a service that updates a snippet' do
      it 'updates a snippet with the provided attributes' do
        expect { subject }.to change { snippet.title }.from(snippet.title).to(options[:title])
          .and change { snippet.file_name }.from(snippet.file_name).to(options[:file_name])
          .and change { snippet.content }.from(snippet.content).to(options[:content])
      end
    end

    shared_examples 'public visibility level restrictions apply' do
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when user is not an admin' do
        it 'responds with an error' do
          expect(subject).to be_error
        end

        it 'does not update snippet to public visibility' do
          original_visibility = snippet.visibility_level

          expect(subject.message).to match('has been restricted')
          expect(snippet.visibility_level).to eq(original_visibility)
        end
      end

      context 'when user is an admin' do
        let(:updater) { admin }

        it 'responds with success' do
          expect(subject).to be_success
        end

        it 'updates the snippet to public visibility' do
          old_visibility = snippet.visibility_level

          expect(subject.payload[:snippet]).not_to be_nil
          expect(snippet.visibility_level).not_to eq(old_visibility)
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end

      context 'when visibility level is passed as a string' do
        before do
          options[:visibility] = 'internal'
          options.delete(:visibility_level)
        end

        it 'assigns the correct visibility level' do
          expect(subject).to be_success
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end
      end
    end

    shared_examples 'snippet update data is tracked' do
      let(:counter) { Gitlab::UsageDataCounters::SnippetCounter }

      it 'increments count when create succeeds' do
        expect { subject }.to change { counter.read(:update) }.by 1
      end

      context 'when update fails' do
        let(:extra_opts) { { title: '' } }

        it 'does not increment count' do
          expect { subject }.not_to change { counter.read(:update) }
        end
      end
    end

    shared_examples 'creates repository and creates file' do
      it 'creates repository' do
        expect(snippet.repository).not_to exist

        subject

        expect(snippet.repository).to exist
      end

      it 'commits the files to the repository' do
        subject

        expect(snippet.blobs.count).to eq 1

        blob = snippet.repository.blob_at('master', options[:file_name])

        expect(blob.data).to eq options[:content]
      end

      context 'when the repository creation fails' do
        before do
          allow(snippet).to receive(:repository_exists?).and_return(false)
        end

        it 'raise an error' do
          response = subject

          expect(response).to be_error
          expect(response.payload[:snippet].errors[:repository].to_sentence).to eq 'Error updating the snippet - Repository could not be created'
        end

        it 'does not try to commit file' do
          expect(service).not_to receive(:create_commit)

          subject
        end
      end
    end

    shared_examples 'commit operation fails' do
      let_it_be(:gitlab_shell) { Gitlab::Shell.new }

      before do
        allow(service).to receive(:create_commit).and_raise(SnippetRepository::CommitError)
      end

      it 'returns error' do
        response = subject

        expect(response).to be_error
        expect(response.payload[:snippet].errors[:repository].to_sentence).to eq 'Error updating the snippet'
      end

      context 'when repository is empty' do
        before do
          allow(service).to receive(:repository_empty?).and_return(true)
        end

        it 'destroys the created repository in disk' do
          subject

          expect(gitlab_shell.repository_exists?(snippet.repository.storage, "#{snippet.disk_path}.git")).to be_falsey
        end

        it 'destroys the SnippetRepository object' do
          subject

          expect(snippet.reload.snippet_repository).to be_nil
        end

        it 'expires the repository exists method cache' do
          response = subject

          expect(response).to be_error
          expect(response.payload[:snippet].repository_exists?).to be_falsey
        end
      end

      context 'when repository is not empty' do
        before do
          allow(service).to receive(:repository_empty?).and_return(false)
        end

        it 'does not destroy the repository' do
          subject

          expect(gitlab_shell.repository_exists?(snippet.repository.storage, "#{snippet.disk_path}.git")).to be_truthy
        end

        it 'does not destroy the snippet repository' do
          subject

          expect(snippet.reload.snippet_repository).not_to be_nil
        end

        it 'expires the repository exists method cache' do
          response = subject

          expect(response).to be_error
          expect(response.payload[:snippet].repository_exists?).to be_truthy
        end
      end

      context 'with snippet modifications' do
        let(:option_keys) { options.stringify_keys.keys }

        it 'rolls back any snippet modifications' do
          orig_attrs = snippet.attributes.select { |k, v| k.in?(option_keys) }

          subject

          persisted_attrs = snippet.reload.attributes.select { |k, v| k.in?(option_keys) }
          expect(orig_attrs).to eq persisted_attrs
        end

        it 'keeps any snippet modifications' do
          subject

          instance_attrs = snippet.attributes.select { |k, v| k.in?(option_keys) }
          expect(options.stringify_keys).to eq instance_attrs
        end
      end
    end

    shared_examples 'updates repository content' do
      it 'commit the files to the repository' do
        blob = snippet.blobs.first
        options[:file_name] = blob.path + '_new'

        expect(blob.data).not_to eq(options[:content])

        subject

        blob = snippet.blobs.first

        expect(blob.path).to eq(options[:file_name])
        expect(blob.data).to eq(options[:content])
      end

      context 'when an error is raised' do
        let(:error_message) { 'foobar' }

        before do
          allow(snippet.snippet_repository).to receive(:multi_files_action).and_raise(SnippetRepository::CommitError, error_message)
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with(error_message)

          subject
        end

        it 'returns error with generic error message' do
          response = subject

          expect(response).to be_error
          expect(response.payload[:snippet].errors[:repository].to_sentence).to eq 'Error updating the snippet'
        end
      end

      it 'returns error if snippet does not have a snippet_repository' do
        allow(snippet).to receive(:snippet_repository).and_return(nil)
        allow(snippet).to receive(:track_snippet_repository).and_return(nil)

        expect(subject).to be_error
      end

      context 'when the repository does not exist' do
        it 'does not try to commit file' do
          allow(snippet).to receive(:repository_exists?).and_return(false)

          expect(service).not_to receive(:create_commit)

          subject
        end
      end
    end

    shared_examples 'committable attributes' do
      context 'when file_name is updated' do
        let(:extra_opts) { { file_name: 'snippet.rb' } }

        it 'commits to repository' do
          expect(service).to receive(:create_commit)
          expect(subject).to be_success
        end
      end

      context 'when content is updated' do
        let(:extra_opts) { { content: 'puts "hello world"' } }

        it 'commits to repository' do
          expect(service).to receive(:create_commit)
          expect(subject).to be_success
        end
      end

      context 'when content or file_name is not updated' do
        let(:options) { { title: 'Test snippet' } }

        it 'does not perform any commit' do
          expect(service).not_to receive(:create_commit)
          expect(subject).to be_success
        end
      end
    end

    shared_examples 'when snippet_files param is present' do
      let(:file_path) { 'CHANGELOG' }
      let(:content) { 'snippet_content' }
      let(:new_title) { 'New title' }
      let(:snippet_files) { [{ action: 'update', previous_path: file_path, file_path: file_path, content: content }] }
      let(:base_opts) do
        {
          title: new_title,
          snippet_files: snippet_files
        }
      end

      it 'updates a snippet with the provided attributes' do
        file_path = 'foo'
        snippet_files[0][:action] = 'move'
        snippet_files[0][:file_path] = file_path

        response = subject
        snippet = response.payload[:snippet]

        expect(response).to be_success
        expect(snippet.title).to eq(new_title)
        expect(snippet.file_name).to eq(file_path)
        expect(snippet.content).to eq(content)
      end

      it 'commit the files to the repository' do
        subject

        blob = snippet.repository.blob_at('master', file_path)

        expect(blob.data).to eq content
      end

      context 'when content or file_name params are present' do
        let(:extra_opts) { { content: 'foo', file_name: 'path' } }

        it 'raises a validation error' do
          response = subject
          snippet = response.payload[:snippet]

          expect(response).to be_error
          expect(snippet.errors.full_messages_for(:content)).to eq ['Content and snippet files cannot be used together']
          expect(snippet.errors.full_messages_for(:file_name)).to eq ['File name and snippet files cannot be used together']
        end
      end

      context 'when snippet_files param is invalid' do
        let(:snippet_files) { [{ action: 'invalid_action' }] }

        it 'raises a validation error' do
          response = subject
          snippet = response.payload[:snippet]

          expect(response).to be_error
          expect(snippet.errors.full_messages_for(:snippet_files)).to eq ['Snippet files have invalid data']
        end
      end

      context 'when an error is raised committing the file' do
        it 'keeps any snippet modifications' do
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:create_repository_for).and_raise(StandardError)
          end

          response = subject
          snippet = response.payload[:snippet]

          expect(response).to be_error
          expect(snippet.title).to eq(new_title)
          expect(snippet.file_name).to eq(file_path)
          expect(snippet.content).to eq(content)
        end
      end
    end

    shared_examples 'only file_name is present' do
      let(:base_opts) do
        {
          file_name: file_name
        }
      end

      shared_examples 'content is not updated' do
        specify do
          existing_content = snippet.blobs.first.data
          response = subject
          snippet = response.payload[:snippet]

          blob = snippet.repository.blob_at('master', file_name)

          expect(blob).not_to be_nil
          expect(response).to be_success
          expect(blob.data).to eq existing_content
        end
      end

      context 'when renaming the file_name' do
        let(:file_name) { 'new_file_name' }

        it_behaves_like 'content is not updated'
      end

      context 'when file_name does not change' do
        let(:file_name) { snippet.blobs.first.path }

        it_behaves_like 'content is not updated'
      end
    end

    shared_examples 'only content is present' do
      let(:content) { 'new_content' }
      let(:base_opts) do
        {
          content: content
        }
      end

      it 'updates the content' do
        response = subject
        snippet = response.payload[:snippet]

        blob = snippet.repository.blob_at('master', snippet.blobs.first.path)

        expect(blob).not_to be_nil
        expect(response).to be_success
        expect(blob.data).to eq content
      end
    end

    context 'when Project Snippet' do
      let_it_be(:project) { create(:project) }
      let!(:snippet) { create(:project_snippet, :repository, author: user, project: project) }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'a service that updates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'snippet update data is tracked'
      it_behaves_like 'updates repository content'
      it_behaves_like 'commit operation fails'
      it_behaves_like 'committable attributes'
      it_behaves_like 'when snippet_files param is present'
      it_behaves_like 'only file_name is present'
      it_behaves_like 'only content is present'
      it_behaves_like 'snippets spam check is performed' do
        before do
          subject
        end
      end

      context 'when snippet does not have a repository' do
        let!(:snippet) { create(:project_snippet, author: user, project: project) }

        it_behaves_like 'creates repository and creates file'
        it_behaves_like 'commit operation fails'
      end
    end

    context 'when PersonalSnippet' do
      let(:project) { nil }
      let!(:snippet) { create(:personal_snippet, :repository, author: user) }

      it_behaves_like 'a service that updates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'snippet update data is tracked'
      it_behaves_like 'updates repository content'
      it_behaves_like 'commit operation fails'
      it_behaves_like 'committable attributes'
      it_behaves_like 'when snippet_files param is present'
      it_behaves_like 'only file_name is present'
      it_behaves_like 'only content is present'
      it_behaves_like 'snippets spam check is performed' do
        before do
          subject
        end
      end

      context 'when snippet does not have a repository' do
        let!(:snippet) { create(:personal_snippet, author: user, project: project) }

        it_behaves_like 'creates repository and creates file'
        it_behaves_like 'commit operation fails'
      end
    end
  end
end
