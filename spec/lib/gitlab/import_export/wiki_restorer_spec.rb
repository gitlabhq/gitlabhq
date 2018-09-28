require 'spec_helper'

describe Gitlab::ImportExport::WikiRestorer do
  describe 'restore a wiki Git repo' do
    let!(:project_with_wiki) { create(:project, :wiki_repo) }
    let!(:project_without_wiki) { create(:project) }
    let!(:project) { create(:project) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { Gitlab::ImportExport::WikiRepoSaver.new(project: project_with_wiki, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }
    let(:restorer) do
      described_class.new(path_to_bundle: bundle_path,
                          shared: shared,
                          project: project.wiki,
                          wiki_enabled: true)
    end

    before do
      allow(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      Gitlab::Shell.new.remove_repository(project_with_wiki.wiki.repository_storage, project_with_wiki.wiki.disk_path)
      Gitlab::Shell.new.remove_repository(project.wiki.repository_storage, project.wiki.disk_path)
    end

    it 'restores the wiki repo successfully' do
      expect(restorer.restore).to be true
    end

    describe "no wiki in the bundle" do
      let(:bundler) { Gitlab::ImportExport::WikiRepoSaver.new(project: project_without_wiki, shared: shared) }

      it 'creates an empty wiki' do
        expect(restorer.restore).to be true

        expect(project.wiki_repository_exists?).to be true
      end
    end
  end
end
