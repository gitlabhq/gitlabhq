require 'spec_helper'

describe Gitlab::ImportExport::RepoRestorer do
  describe 'bundle a project Git repo' do
    let(:user) { create(:user) }
    let!(:project_with_repo) { create(:project, :repository, name: 'test-repo-restorer', path: 'test-repo-restorer') }
    let!(:project) { create(:project) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { Gitlab::ImportExport::RepoSaver.new(project: project_with_repo, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }
    let(:restorer) do
      described_class.new(path_to_bundle: bundle_path,
                          shared: shared,
                          project: project)
    end

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      FileUtils.rm_rf(project_with_repo.repository.path_to_repo)
      FileUtils.rm_rf(project.repository.path_to_repo)
    end

    it 'restores the repo successfully' do
      expect(restorer.restore).to be true
    end

    it 'has the webhooks' do
      restorer.restore

      expect(Gitlab::Git::Hook.new('post-receive', project.repository.raw_repository)).to exist
    end
  end
end
