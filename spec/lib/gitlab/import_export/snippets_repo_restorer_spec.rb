# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::SnippetsRepoRestorer, :clean_gitlab_redis_repository_cache, feature_category: :importers do
  describe 'bundle a snippet Git repo' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    let!(:snippet1) { create(:project_snippet, project: project, author: user) }
    let!(:snippet2) { create(:project_snippet, project: project, author: user) }
    let(:shared) { project.import_export_shared }
    let(:exporter) { Gitlab::ImportExport::SnippetsRepoSaver.new(current_user: user, project: project, shared: shared) }
    let(:bundle_dir) { ::Gitlab::ImportExport.snippets_repo_bundle_path(shared.export_path) }
    let(:service) { instance_double(Gitlab::ImportExport::SnippetRepoRestorer) }
    let(:restorer) do
      described_class.new(user: user, shared: shared, project: project)
    end

    after do
      FileUtils.rm_rf(shared.export_path)
    end

    shared_examples 'imports snippet repositories' do
      before do
        snippet1.snippet_repository&.delete
        # We need to explicitly invalidate repository.exists? from cache by calling repository.expire_exists_cache.
        # Previously, we didn't have to do this because snippet1.repository_exists? would hit Rails.cache, which is a
        # NullStore, thus cache.read would always be false.
        # Now, since we are using a separate instance of Redis, ie Gitlab::Redis::RepositoryCache,
        # snippet.repository_exists? would still be true because snippet.repository.remove doesn't invalidate the
        # cache (snippet.repository.remove only makes gRPC call to Gitaly).
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107232#note_1214358593 for more.
        snippet1.repository.expire_exists_cache
        snippet1.repository.remove

        snippet2.snippet_repository&.delete
        snippet2.repository.expire_exists_cache
        snippet2.repository.remove
      end

      specify do
        expect(snippet1.repository_exists?).to be false
        expect(snippet2.repository_exists?).to be false

        allow_any_instance_of(Snippets::RepositoryValidationService).to receive(:execute).and_return(ServiceResponse.success)
        expect(Gitlab::ImportExport::SnippetRepoRestorer).to receive(:new).with(hash_including(snippet: snippet1, path_to_bundle: bundle_path(snippet1))).and_call_original
        expect(Gitlab::ImportExport::SnippetRepoRestorer).to receive(:new).with(hash_including(snippet: snippet2, path_to_bundle: bundle_path(snippet2))).and_call_original
        expect(restorer.restore).to be_truthy

        snippet1.repository.expire_exists_cache
        snippet2.repository.expire_exists_cache

        expect(snippet1.blobs).not_to be_empty
        expect(snippet2.blobs).not_to be_empty
      end
    end

    context 'when export has no snippet repository bundle' do
      before do
        expect(Dir.exist?(bundle_dir)).to be false
      end

      it_behaves_like 'imports snippet repositories'
    end

    context 'when export has snippet repository bundles and snippets without them' do
      let!(:snippet1) { create(:project_snippet, :repository, project: project, author: user) }
      let!(:snippet2) { create(:project_snippet, project: project, author: user) }

      before do
        exporter.save # rubocop:disable Rails/SaveBang

        expect(File.exist?(bundle_path(snippet1))).to be true
        expect(File.exist?(bundle_path(snippet2))).to be false
      end

      it_behaves_like 'imports snippet repositories'
    end

    context 'when export has only snippet bundles' do
      let!(:snippet1) { create(:project_snippet, :repository, project: project, author: user) }
      let!(:snippet2) { create(:project_snippet, :repository, project: project, author: user) }

      before do
        exporter.save # rubocop:disable Rails/SaveBang

        expect(File.exist?(bundle_path(snippet1))).to be true
        expect(File.exist?(bundle_path(snippet2))).to be true
      end

      it_behaves_like 'imports snippet repositories'
    end

    context 'when any of the snippet repositories cannot be created' do
      it 'continues processing other snippets and returns false' do
        allow(Gitlab::ImportExport::SnippetRepoRestorer).to receive(:new).with(hash_including(snippet: snippet1)).and_return(service)
        allow(service).to receive(:restore).and_return(false)

        expect(Gitlab::ImportExport::SnippetRepoRestorer).to receive(:new).with(hash_including(snippet: snippet2)).and_call_original

        expect(restorer.restore).to be false
      end
    end

    def bundle_path(snippet)
      File.join(bundle_dir, ::Gitlab::ImportExport.snippet_repo_bundle_filename_for(snippet))
    end
  end
end
