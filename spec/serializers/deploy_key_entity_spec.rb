require 'spec_helper'

describe DeployKeyEntity do
  include RequestAwareEntity

  let(:user) { create(:user) }
  let(:project) { create(:project, :internal)}
  let(:project_private) { create(:project, :private)}
  let!(:project_pending_delete) { create(:project, :internal, pending_delete: true) }
  let(:deploy_key) { create(:deploy_key) }
  let!(:deploy_key_internal) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }
  let!(:deploy_key_private)  { create(:deploy_keys_project, project: project_private, deploy_key: deploy_key) }
  let!(:deploy_key_pending_delete) { create(:deploy_keys_project, project: project_pending_delete, deploy_key: deploy_key) }

  let(:entity) { described_class.new(deploy_key, user: user) }

  describe 'returns deploy keys with projects a user can read' do
    let(:expected_result) do
      {
        id: deploy_key.id,
        user_id: deploy_key.user_id,
        title: deploy_key.title,
        fingerprint: deploy_key.fingerprint,
        destroyed_when_orphaned: true,
        almost_orphaned: false,
        created_at: deploy_key.created_at,
        updated_at: deploy_key.updated_at,
        can_edit: false,
        deploy_keys_projects: [
          {
            can_push: false,
            project:
            {
              id: project.id,
              name: project.name,
              full_path: project_path(project),
              full_name: project.full_name
            }
          }
        ]
      }
    end

    it { expect(entity.as_json).to eq(expected_result) }
  end

  describe 'returns can_edit true if user is a master of project' do
    before do
      project.add_master(user)
    end

    it { expect(entity.as_json).to include(can_edit: true) }
  end

  describe 'returns can_edit true if a user admin' do
    let(:user) { create(:user, :admin) }

    it { expect(entity.as_json).to include(can_edit: true) }
  end
end
