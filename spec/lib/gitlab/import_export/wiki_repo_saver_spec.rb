# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::WikiRepoSaver do
  describe 'bundle a wiki Git repo' do
    set(:user) { create(:user) }
    let!(:project) { create(:project, :wiki_repo) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:wiki_bundler) { described_class.new(project: project, shared: shared) }
    let!(:project_wiki) { ProjectWiki.new(project, user) }

    before do
      project.add_maintainer(user)
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end
      project_wiki.wiki
      project_wiki.create_page("index", "test content")
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(wiki_bundler.save).to be true
    end

    context 'when the repo is empty' do
      let!(:project) { create(:project) }

      it 'bundles the repo successfully' do
        expect(wiki_bundler.save).to be true
      end
    end
  end
end
