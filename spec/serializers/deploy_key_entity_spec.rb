# frozen_string_literal: true

require 'spec_helper'

describe DeployKeyEntity do
  include RequestAwareEntity

  let(:user) { create(:user) }
  let(:project) { create(:project, :internal)}
  let(:project_private) { create(:project, :private)}
  let(:deploy_key) { create(:deploy_key) }

  let(:entity) { described_class.new(deploy_key, user: user) }

  before do
    project.deploy_keys << deploy_key
    project_private.deploy_keys << deploy_key
  end

  describe 'returns deploy keys with projects a user can read' do
    let(:expected_result) do
      {
        id: deploy_key.id,
        user_id: deploy_key.user_id,
        title: deploy_key.title,
        fingerprint: deploy_key.fingerprint,
        fingerprint_sha256: deploy_key.fingerprint_sha256,
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

  context 'user is an admin' do
    let(:user) { create(:user, :admin) }

    it { expect(entity.as_json).to include(can_edit: true) }
  end

  context 'user is a project maintainer' do
    before do
      project.add_maintainer(user)
    end

    context 'project deploy key' do
      it { expect(entity.as_json).to include(can_edit: true) }
    end

    context 'public deploy key' do
      let(:deploy_key_public) { create(:deploy_key, public: true) }
      let(:entity_public) { described_class.new(deploy_key_public, { user: user, project: project }) }

      before do
        project.deploy_keys << deploy_key_public
      end

      it { expect(entity_public.as_json).to include(can_edit: true) }
    end
  end
end
