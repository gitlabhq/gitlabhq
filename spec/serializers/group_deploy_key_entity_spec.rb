# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployKeyEntity do
  include RequestAwareEntity

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:group_deploy_key) { create(:group_deploy_key) }
  let(:options) { { user: user } }

  let(:entity) { described_class.new(group_deploy_key, options) }

  before do
    group.group_deploy_keys << group_deploy_key
  end

  describe 'returns group deploy keys with a group a user can read' do
    let(:expected_result) do
      {
        id: group_deploy_key.id,
        user_id: group_deploy_key.user_id,
        title: group_deploy_key.title,
        fingerprint: group_deploy_key.fingerprint,
        fingerprint_sha256: group_deploy_key.fingerprint_sha256,
        created_at: group_deploy_key.created_at,
        expires_at: group_deploy_key.expires_at,
        updated_at: group_deploy_key.updated_at,
        can_edit: false,
        group_deploy_keys_groups: [
          {
            can_push: false,
            group:
            {
              id: group.id,
              name: group.name,
              full_path: group.full_path,
              full_name: group.full_name
            }
          }
        ]
      }
    end

    it { expect(entity.as_json).to eq(expected_result) }
  end
end
