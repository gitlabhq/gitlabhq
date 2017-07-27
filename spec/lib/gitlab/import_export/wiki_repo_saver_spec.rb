require 'spec_helper'

describe Gitlab::ImportExport::WikiRepoSaver do
  describe 'bundle a wiki Git repo' do
    let(:user) { create(:user) }
    let!(:project) { create(:empty_project, :public, name: 'searchable_project') }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:wiki_bundler) { described_class.new(project: project, shared: shared) }
    let!(:project_wiki) { ProjectWiki.new(project, user) }

    before do
      project.team << [user, :master]
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
      project_wiki.wiki
      project_wiki.create_page("index", "test content")
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(wiki_bundler.save).to be true
    end
  end
end
