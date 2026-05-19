# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DeployKeysController, :enable_admin_mode, :with_current_organization,
  feature_category: :continuous_delivery do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'POST /admin/deploy_keys' do
    let(:deploy_key_attrs) { attributes_for(:deploy_key) }

    subject(:post_create) do
      post admin_deploy_keys_path, params: { deploy_key: deploy_key_attrs }
    end

    it 'creates a deploy key scoped to Current.organization', :aggregate_failures do
      expect { post_create }.to change { DeployKey.count }.by(1)

      created_key = DeployKey.last
      expect(created_key.organization).to eq(current_organization)
      expect(response).to redirect_to(admin_deploy_keys_path)
    end
  end
end
