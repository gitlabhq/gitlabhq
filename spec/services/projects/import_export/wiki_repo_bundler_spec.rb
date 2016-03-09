require 'spec_helper'

describe Projects::ImportExport::WikiRepoBundler, services: true do
  describe :bundle do

    let(:user) { create(:user) }
    let!(:project) { create(:project, :public, name: 'searchable_project') }
    let(:export_path) { "#{Dir::tmpdir}/project_tree_saver_spec" }
    let(:shared) { Projects::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
    let(:wiki_bundler) { Projects::ImportExport::WikiRepoBundler.new(project: project, shared: shared) }
    let!(:project_wiki) { ProjectWiki.new(project, user) }

    before(:each) do
      project.team << [user, :master]
      allow_any_instance_of(Projects::ImportExport).to receive(:storage_path).and_return(export_path)
      project_wiki.wiki
      project_wiki.create_page("index", "test content")
    end

    after(:each) do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(wiki_bundler.bundle).to be true
    end
  end
end
