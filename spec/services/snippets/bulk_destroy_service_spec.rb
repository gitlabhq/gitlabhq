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

  subject(:service) { described_class.new(service_user, snippets) }

  describe '#execute' do
    it 'deletes the snippets in bulk' do
      response = nil

      expect(::Repositories::DestroyService).to receive(:new).with(personal_snippet.repository).and_call_original
      expect(::Repositories::DestroyService).to receive(:new).with(project_snippet.repository).and_call_original

      aggregate_failures do
        expect do
          response = subject.execute
        end.to change { Snippet.count }.by(-2)

        expect(response).to be_success
        expect(repository_exists?(personal_snippet)).to be_falsey
        expect(repository_exists?(project_snippet)).to be_falsey
      end
    end

    it 'loads projected snippets and preloads repositories for deletion', :aggregate_failures do
      loaded_snippets = []
      other_project = create(:project)
      other_project.add_developer(user)
      create_list(:project_snippet, 2, :repository, project: project, author: user)
      create(:project_snippet, :repository, project: other_project, author: user)

      allow(::Repositories::DestroyService).to receive(:new) do |repository|
        loaded_snippets << repository.container

        instance_double(::Repositories::DestroyService, execute: { status: :success })
      end

      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        service.execute(skip_authorization: true)
      end

      snippet_queries = recorder.log.select { |query| query.include?('FROM "snippets"') }
      snippet_repository_queries = recorder.log.select { |query| query.include?('FROM "snippet_repositories"') }
      route_queries = recorder.log.select { |query| query.include?('FROM "routes"') }

      expect(snippet_queries).to include(a_string_matching(/SELECT .*"snippets"\."id"/))
      expect(snippet_queries).not_to include(a_string_matching('"snippets"."content"'))
      expect(snippet_repository_queries.count).to eq(1)
      # Routes for all projects are fetched by one bounded preload query.
      expect(route_queries.count).to eq(1)
      expect(loaded_snippets).to include(be_a(PersonalSnippet), be_a(ProjectSnippet))
      expect(loaded_snippets.map { |snippet| snippet.has_attribute?(:organization_id) }).to all(be(true))
      expect(loaded_snippets.map { |snippet| snippet.has_attribute?(:content) }).to all(be(false))
    end

    it 'destroys snippet records in batches', :aggregate_failures do
      response = nil
      create(:personal_snippet, :repository, author: user)
      create(:project_snippet, :repository, project: project, author: user)
      stub_const("#{described_class}::BATCH_SIZE", 2)

      recorder = ActiveRecord::QueryRecorder.new do
        response = service.execute
      end

      batch_boundary_queries = recorder.log.select do |query|
        query.include?('FROM "snippets"') && query.include?('OFFSET 2')
      end
      snippet_delete_queries = recorder.log.select { |query| query.include?('DELETE FROM "snippets"') }

      expect(response).to be_success
      expect(Snippet.where(author: user)).to be_empty
      expect(batch_boundary_queries.count).to eq(2)
      expect(snippet_delete_queries.count).to eq(4)
    end

    it 'preserves snippet destroy callbacks for associated records', :aggregate_failures do
      personal_note = create(:note_on_personal_snippet, noteable: personal_snippet)
      project_note = create(:note_on_project_snippet, noteable: project_snippet, project: project)
      statistic_snippet_ids = [personal_snippet.statistics.snippet_id, project_snippet.statistics.snippet_id]

      expect do
        service.execute
      end.to change { Note.where(id: [personal_note.id, project_note.id]).count }.from(2).to(0)
        .and change { SnippetStatistics.where(snippet_id: statistic_snippet_ids).count }.from(2).to(0)
    end

    it 'runs project snippet statistics callbacks on projected snippets', :aggregate_failures do
      project_snippet.statistics.update!(repository_size: 100)

      expect(project.reload.statistics.snippets_size).to eq(100)

      expect do
        service.execute
      end.to change { project.reload.statistics.snippets_size }.from(100).to(0)
    end

    it 'runs personal snippet upload callbacks on projected snippets', :aggregate_failures do
      upload = create(:upload, :personal_snippet_upload, :with_file, model: personal_snippet)

      expect do
        service.execute
      end.to change { Upload.exists?(upload.id) }.from(true).to(false)
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
          expect(response.reason).to eq error_reason
        end
      end

      it 'no record is deleted' do
        expect do
          subject.execute
        end.not_to change { Snippet.count }
      end
    end

    context 'when user does not have access to remove the snippet' do
      let(:service_user) { create(:user) }

      it_behaves_like 'error is raised' do
        let(:error_message) { described_class::NO_ACCESS_ERROR[:message] }
        let(:error_reason) { described_class::NO_ACCESS_ERROR[:reason] }
      end

      context 'when skip_authorization option is passed' do
        subject { described_class.new(service_user, snippets).execute(skip_authorization: true) }

        it 'returns a ServiceResponse success response' do
          expect(subject).to be_success
        end

        it 'deletes all the snippets that belong to the user' do
          expect { subject }.to change { Snippet.count }.by(-2)
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
        let(:error_message) { described_class::SNIPPET_REPOSITORIES_DELETE_ERROR[:message] }
        let(:error_reason) { described_class::SNIPPET_REPOSITORIES_DELETE_ERROR[:reason] }
      end
    end

    context 'when an error is raised deleting the records' do
      before do
        allow_next_found_instance_of(PersonalSnippet) do |snippet|
          allow(snippet).to receive(:destroy!).and_raise(ActiveRecord::ActiveRecordError)
        end
      end

      it_behaves_like 'error is raised' do
        let(:error_message) { described_class::SNIPPETS_DELETE_ERROR[:message] }
        let(:error_reason) { described_class::SNIPPETS_DELETE_ERROR[:reason] }
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
        end.to change { Snippet.count }.by(-3)

        expect(response).to be_success
      end
    end
  end

  def repository_exists?(snippet, path = snippet.disk_path + ".git")
    gitlab_shell.repository_exists?(snippet.snippet_repository.shard_name, path)
  end
end
