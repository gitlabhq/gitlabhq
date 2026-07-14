# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::HasImportSource, feature_category: :importers do
  let_it_be(:snippet_not_imported) { create(:project_snippet, :repository) }
  let_it_be(:snippet_imported) { create(:project_snippet, imported_from: :bitbucket) }
  let_it_be(:merge_request_imported) { create(:project_snippet, imported_from: :fogbugz) }
  let_it_be(:merge_request_imported_bb_cloud) { create(:project_snippet, imported_from: :bitbucket) }
  let_it_be(:merge_request_imported_github) { create(:project_snippet, imported_from: :github) }
  let_it_be(:merge_request_imported_gitea) { create(:project_snippet, imported_from: :gitea) }
  let_it_be(:snippet_imported_offline_transfer) { create(:project_snippet, imported_from: :offline_transfer) }

  describe '#imported?' do
    it 'returns the correct imported state' do
      expect(snippet_not_imported.imported?).to be(false)
      expect(snippet_imported.imported?).to be(true)
      expect(merge_request_imported.imported?).to be(true)
      expect(merge_request_imported_bb_cloud.imported?).to be(true)
      expect(merge_request_imported_github.imported?).to be(true)
      expect(merge_request_imported_gitea.imported?).to be(true)
      expect(snippet_imported_offline_transfer.imported?).to be(true)
    end
  end

  describe '#imported_from' do
    it 'returns the correct importer' do
      expect(snippet_not_imported.imported_from).to eq('none')
      expect(snippet_imported.imported_from).to eq('bitbucket')
      expect(merge_request_imported.imported_from).to eq('fogbugz')
      expect(merge_request_imported_bb_cloud.imported_from).to eq('bitbucket')
      expect(merge_request_imported_github.imported_from).to eq('github')
      expect(merge_request_imported_gitea.imported_from).to eq('gitea')
    end
  end

  describe '#imported_from_[importer]?' do
    it 'returns the correct boolean response' do
      expect(snippet_not_imported.imported_from_github?).to be(false)
      expect(snippet_imported.imported_from_bitbucket?).to be(true)
      expect(merge_request_imported.imported_from_gitlab_migration?).to be(false)
      expect(merge_request_imported_github.imported_from_gitlab_project?).to be(false)
      expect(merge_request_imported_gitea.imported_from_gitea?).to be(true)
      expect(snippet_imported_offline_transfer.imported_from_offline_transfer?).to be(true)
      expect(snippet_imported_offline_transfer.imported_from_gitlab_migration?).to be(false)
    end
  end
end
