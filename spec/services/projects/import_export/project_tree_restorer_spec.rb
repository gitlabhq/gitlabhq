require 'spec_helper'

describe Projects::ImportExport::ProjectTreeRestorer, services: true do
  describe :restore do

    let(:user) { create(:user) }
    let(:project_tree_restorer) { Projects::ImportExport::ProjectTreeRestorer.new(path: "fixtures/import_export/project.json", user: user) }

    context 'JSON' do
      let(:restored_project_json) do
        project_tree_restorer.restore
      end

      it 'restores models based on JSON' do
        expect(restored_project_json).to be true
      end
    end
  end
end
