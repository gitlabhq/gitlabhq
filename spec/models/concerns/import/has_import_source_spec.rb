# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::HasImportSource, feature_category: :importers do
  let_it_be(:snippet_not_imported) { create(:snippet, :repository) }
  let_it_be(:snippet_imported) { create(:snippet, imported_from: :bitbucket) }
  let_it_be(:merge_request_imported) { create(:snippet, imported_from: :fogbugz) }

  describe '#imported?' do
    it 'returns the correct imported state' do
      expect(snippet_not_imported.imported?).to eq(false)
      expect(snippet_imported.imported?).to eq(true)
      expect(merge_request_imported.imported?).to eq(true)
    end
  end

  describe '#imported_from' do
    it 'returns the correct importer' do
      expect(snippet_not_imported.imported_from).to eq('none')
      expect(snippet_imported.imported_from).to eq('bitbucket')
      expect(merge_request_imported.imported_from).to eq('fogbugz')
    end
  end

  describe '#imported_from_[importer]?' do
    it 'returns the correct boolean response' do
      expect(snippet_not_imported.imported_from_github?).to eq(false)
      expect(snippet_imported.imported_from_bitbucket?).to eq(true)
      expect(merge_request_imported.imported_from_gitlab_migration?).to eq(false)
    end
  end
end
