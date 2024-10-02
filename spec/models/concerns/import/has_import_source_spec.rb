# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::HasImportSource, feature_category: :importers do
  let_it_be(:snippet_not_imported) { create(:project_snippet, :repository) }
  let_it_be(:snippet_imported) { create(:project_snippet, imported_from: :bitbucket) }
  let_it_be(:merge_request_imported) { create(:project_snippet, imported_from: :fogbugz) }
  let_it_be(:merge_request_imported_bb_cloud) { create(:project_snippet, imported_from: :bitbucket) }
  let_it_be(:merge_request_imported_github) { create(:project_snippet, imported_from: :github) }
  let_it_be(:merge_request_imported_gitea) { create(:project_snippet, imported_from: :gitea) }

  describe '#imported?' do
    it 'returns the correct imported state' do
      expect(snippet_not_imported.imported?).to eq(false)
      expect(snippet_imported.imported?).to eq(true)
      expect(merge_request_imported.imported?).to eq(true)
      expect(merge_request_imported_bb_cloud.imported?).to eq(true)
      expect(merge_request_imported_github.imported?).to eq(true)
      expect(merge_request_imported_gitea.imported?).to eq(true)
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
      expect(snippet_not_imported.imported_from_github?).to eq(false)
      expect(snippet_imported.imported_from_bitbucket?).to eq(true)
      expect(merge_request_imported.imported_from_gitlab_migration?).to eq(false)
      expect(merge_request_imported_github.imported_from_gitlab_project?).to eq(false)
      expect(merge_request_imported_gitea.imported_from_gitea?).to eq(true)
    end
  end
end
