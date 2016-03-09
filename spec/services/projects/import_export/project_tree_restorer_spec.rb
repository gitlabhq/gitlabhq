require 'spec_helper'

describe Projects::ImportExport::ProjectTreeRestorer, services: true do
  describe :restore do

    let(:user) { create(:user) }
    let(:project_tree_restorer) { Projects::ImportExport::ProjectTreeRestorer.new(path: "fixtures/import_export/project.json") }

    before(:each) do
       #allow(project_tree_restorer)
       #  .to receive(:full_path).and_return("fixtures/import_export/project.json")
    end

    context 'JSON' do
      let(:restored_project_json) do
        project_tree_restorer.restore
        #project_json(project_tree_restorer.full_path)
      end

      it 'restores models based on JSON' do
        expect(restored_project_json).to be true
      end
    end
  end

  def project_json
    JSON.parse(IO.read("fixtures/import_export/project.json"))
  end
end
