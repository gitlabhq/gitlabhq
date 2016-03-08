require 'spec_helper'

describe Projects::ImportExport::RepoBundler, services: true do
  describe :bundle do

    let(:user) { create(:user) }
    let!(:project) { create(:project, :public, name: 'searchable_project') }
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:shared) { Projects::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:bundler) { Projects::ImportExport::RepoBundler.new(project: project, shared: shared) }

    before(:each) do
      project.team << [user, :master]
      allow_any_instance_of(Projects::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after(:each) do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(bundler.bundle).to be true
    end
  end
end
