require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeRestorer, services: true do
  describe 'restore project tree' do

    let(:user) { create(:user) }
    let(:namespace) { create(:namespace, owner: user) }
    let(:project_tree_restorer) { described_class.new(path: Rails.root.join("spec/lib/gitlab/import_export/"), user: user, project_path: 'project', namespace_id: namespace.id) }

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
