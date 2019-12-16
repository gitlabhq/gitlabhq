# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::RepoRestorer do
  include GitHelpers

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
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        FileUtils.rm_rf(project_with_repo.repository.path_to_repo)
        FileUtils.rm_rf(project.repository.path_to_repo)
      end
    end

    it 'restores the repo successfully' do
      expect(restorer.restore).to be_truthy
    end
  end
end
