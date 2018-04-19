require 'spec_helper'

describe Gitlab::ImportExport::RepoSaver do
  describe 'bundle a project Git repo' do
    let(:user) { create(:user) }
    let!(:project) { create(:project, :public, name: 'searchable_project') }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { described_class.new(project: project, shared: shared) }

    before do
      project.add_master(user)
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(bundler.save).to be true
    end
  end
end
