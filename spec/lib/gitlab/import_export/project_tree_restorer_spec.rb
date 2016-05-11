require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeRestorer, services: true do
  describe 'restore project tree' do

    let(:user) { create(:user) }
    let(:namespace) { create(:namespace, owner: user) }
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: "../../../spec/lib/gitlab/import_export/", project_path: 'path') }
    let(:project_tree_restorer) { described_class.new(user: user, shared: shared, namespace_id: namespace.id) }

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
