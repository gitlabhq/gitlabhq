# frozen_string_literal: true

require 'spec_helper'

describe Snippets::UpdateService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create :user, admin: true }
    let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
    let(:options) do
      {
        title: 'Test snippet',
        file_name: 'snippet.rb',
        content: 'puts "hello world"',
        visibility_level: visibility_level
      }
    end
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
        let(:options) { { title: '' } }

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

      context 'when the repository does not exist' do
        it 'does not try to commit file' do
          allow(snippet).to receive(:repository_exists?).and_return(false)

          expect(service).not_to receive(:create_commit)

          subject
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(version_snippets: false)
        end

        it 'does not create repository' do
          subject

          expect(snippet.repository).not_to exist
        end

        it 'does not try to commit file' do
          expect(service).not_to receive(:create_commit)

          subject
        end
      end

      it 'returns error when the commit action fails' do
        allow_next_instance_of(SnippetRepository) do |instance|
          allow(instance).to receive(:multi_files_action).and_raise(SnippetRepository::CommitError)
        end

        response = subject

        expect(response).to be_error
        expect(response.payload[:snippet].errors.full_messages).to eq ['Repository Error updating the snippet']
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

      it 'returns error when the commit action fails' do
        allow(snippet.snippet_repository).to receive(:multi_files_action).and_raise(SnippetRepository::CommitError)

        response = subject

        expect(response).to be_error
        expect(response.payload[:snippet].errors.full_messages).to eq ['Repository Error updating the snippet']
      end

      it 'returns error if snippet does not have a snippet_repository' do
        allow(snippet).to receive(:snippet_repository).and_return(nil)

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

      context 'when snippet does not have a repository' do
        let!(:snippet) { create(:project_snippet, author: user, project: project) }

        it_behaves_like 'creates repository and creates file'
      end
    end

    context 'when PersonalSnippet' do
      let(:project) { nil }
      let!(:snippet) { create(:personal_snippet, :repository, author: user) }

      it_behaves_like 'a service that updates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'snippet update data is tracked'
      it_behaves_like 'updates repository content'

      context 'when snippet does not have a repository' do
        let!(:snippet) { create(:personal_snippet, author: user, project: project) }

        it_behaves_like 'creates repository and creates file'
      end
    end
  end
end
