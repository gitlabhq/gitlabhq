# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WikiFileFinder, feature_category: :global_search do
  describe '#find' do
    let_it_be(:project) do
      create(:project, :public, :wiki_repo).tap do |project|
        project.wiki.create_page('Files/Title', 'Content')
        project.wiki.create_page('CHANGELOG', 'Files example')
      end
    end

    it_behaves_like 'file finder' do
      subject { described_class.new(project, project.wiki.default_branch) }

      let(:expected_file_by_path) { 'Files/Title.md' }
      let(:expected_file_by_content) { 'CHANGELOG.md' }
    end

    it 'does not include .gitlab/redirects.yml' do
      results = described_class.new(project, project.wiki.default_branch).find(Wiki::REDIRECTS_YML)
      expect(results.map(&:blob_path)).not_to include Wiki::REDIRECTS_YML
    end
  end
end
