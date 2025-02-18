# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::BulkDestroyService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }
  let!(:personal_snippet) { create(:personal_snippet, :repository, author: user) }
  let!(:project_snippet) { create(:project_snippet, :repository, project: project, author: user) }
  let(:snippets) { user.snippets }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:service_user) { user }

  before do
    project.add_developer(user)
  end

  subject { described_class.new(service_user, snippets) }

  describe '#execute' do
    it 'deletes the snippets in bulk' do
      response = nil

      expect(::Repositories::DestroyService).to receive(:new).with(personal_snippet.repository).and_call_original
      expect(::Repositories::DestroyService).to receive(:new).with(project_snippet.repository).and_call_original

      aggregate_failures do
        expect do
          response = subject.execute
        end.to change(Snippet, :count).by(-2)

        expect(response).to be_success
        expect(repository_exists?(personal_snippet)).to be_falsey
        expect(repository_exists?(project_snippet)).to be_falsey
      end
    end

    context 'when snippets is empty' do
      let(:snippets) { Snippet.none }

      it 'returns a ServiceResponse success response' do
        response = subject.execute

        expect(response).to be_success
        expect(response.message).to eq 'No snippets found.'
      end
    end

    shared_examples 'error is raised' do
      it 'returns error' do
        response = subject.execute

        aggregate_failures do
          expect(response).to be_error
          expect(response.message).to eq error_message
        end
      end

      it 'no record is deleted' do
        expect do
          subject.execute
        end.not_to change(Snippet, :count)
      end
    end

    context 'when user does not have access to remove the snippet' do
      let(:service_user) { create(:user) }

      it_behaves_like 'error is raised' do
        let(:error_message) { "You don't have access to delete these snippets." }
      end

      context 'when skip_authorization option is passed' do
        subject { described_class.new(service_user, snippets).execute(skip_authorization: true) }

        it 'returns a ServiceResponse success response' do
          expect(subject).to be_success
        end

        it 'deletes all the snippets that belong to the user' do
          expect { subject }.to change(Snippet, :count).by(-2)
        end
      end
    end

    context 'when an error is raised deleting the repository' do
      before do
        allow_next_instance_of(::Repositories::DestroyService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :error })
        end
      end

      it_behaves_like 'error is raised' do
        let(:error_message) { 'Failed to delete snippet repositories.' }
      end
    end

    context 'when an error is raised deleting the records' do
      before do
        allow(snippets).to receive(:destroy_all).and_raise(ActiveRecord::ActiveRecordError)
      end

      it_behaves_like 'error is raised' do
        let(:error_message) { 'Failed to remove snippets.' }
      end
    end

    context 'when snippet does not have a repository attached' do
      let!(:snippet_without_repo) { create(:personal_snippet, author: user) }

      it 'returns success' do
        response = nil

        expect(::Repositories::DestroyService).to receive(:new).with(personal_snippet.repository).and_call_original
        expect(::Repositories::DestroyService).to receive(:new).with(project_snippet.repository).and_call_original
        expect(::Repositories::DestroyService).to receive(:new).with(snippet_without_repo.repository).and_call_original

        expect do
          response = subject.execute
        end.to change(Snippet, :count).by(-3)

        expect(response).to be_success
      end
    end
  end

  def repository_exists?(snippet, path = snippet.disk_path + ".git")
    gitlab_shell.repository_exists?(snippet.snippet_repository.shard_name, path)
  end
end
