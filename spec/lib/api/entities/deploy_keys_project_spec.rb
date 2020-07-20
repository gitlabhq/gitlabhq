# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::DeployKeysProject do
  describe '#as_json' do
    subject { entity.as_json }

    let(:deploy_keys_project) { create(:deploy_keys_project, :write_access) }
    let(:entity) { described_class.new(deploy_keys_project) }

    it 'includes basic fields', :aggregate_failures do
      deploy_key = deploy_keys_project.deploy_key

      is_expected.to include(
        id: deploy_key.id,
        title: deploy_key.title,
        created_at: deploy_key.created_at,
        expires_at: deploy_key.expires_at,
        key: deploy_key.key,
        can_push: deploy_keys_project.can_push
      )
    end
  end
end
