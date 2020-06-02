# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::SnippetRepoRestorer do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let(:snippet) { create(:project_snippet, project: project, author: user) }

  let(:shared) { project.import_export_shared }
  let(:exporter) { Gitlab::ImportExport::SnippetsRepoSaver.new(project: project, shared: shared, current_user: user) }
  let(:restorer) do
    described_class.new(user: user,
                        shared: shared,
                        snippet: snippet,
                        path_to_bundle: snippet_bundle_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  shared_examples 'no bundle file present' do
    it 'creates the repository from the database content' do
      expect(snippet.repository_exists?).to be_falsey

      aggregate_failures do
        expect do
          expect(restorer.restore).to be_truthy
        end.to change { SnippetRepository.count }.by(1)

        blob = snippet.repository.blob_at('HEAD', snippet.file_name)
        expect(blob).not_to be_nil
        expect(blob.data).to eq(snippet.content)
      end
    end
  end

  context 'when the snippet does not have a bundle file path' do
    let(:snippet_bundle_path) { nil }

    it_behaves_like 'no bundle file present'
  end

  context 'when the snippet bundle path is not present' do
    let(:snippet_bundle_path) { 'foo' }

    it_behaves_like 'no bundle file present'
  end

  context 'when the snippet bundle exists' do
    let!(:snippet_with_repo) { create(:project_snippet, :repository, project: project) }
    let(:bundle_path) { ::Gitlab::ImportExport.snippets_repo_bundle_path(shared.export_path) }
    let(:snippet_bundle_path) { File.join(bundle_path, "#{snippet_with_repo.hexdigest}.bundle") }
    let(:result) { exporter.save }

    before do
      expect(exporter.save).to be_truthy
    end

    it 'creates the repository from the bundle' do
      expect(snippet.repository_exists?).to be_falsey
      expect(snippet.snippet_repository).to be_nil
      expect(snippet.repository).to receive(:create_from_bundle).and_call_original

      expect(restorer.restore).to be_truthy
      expect(snippet.repository_exists?).to be_truthy
      expect(snippet.snippet_repository).not_to be_nil
    end

    it 'sets same shard in snippet repository as in the repository storage' do
      expect(snippet).to receive(:repository_storage).and_return('picked')
      expect(snippet.repository).to receive(:create_from_bundle)

      restorer.restore

      expect(snippet.snippet_repository.shard_name).to eq 'picked'
    end
  end
end
