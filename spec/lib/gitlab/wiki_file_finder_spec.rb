# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WikiFileFinder do
  describe '#find' do
    let(:project) { create(:project, :public, :wiki_repo) }
    let(:wiki) { build(:project_wiki, project: project) }

    before do
      wiki.create_page('Files/Title', 'Content')
      wiki.create_page('CHANGELOG', 'Files example')
    end

    it_behaves_like 'file finder' do
      subject { described_class.new(project, project.wiki.default_branch) }

      let(:expected_file_by_path) { 'Files/Title.md' }
      let(:expected_file_by_content) { 'CHANGELOG.md' }
    end
  end
end
