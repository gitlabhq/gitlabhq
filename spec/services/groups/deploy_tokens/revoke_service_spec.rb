# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokens::RevokeService, feature_category: :deployment_management do
  let_it_be(:entity) { create(:group) }
  let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [entity]) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token_params) { { id: deploy_token.id } }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    it "revokes a group deploy token" do
      expect(deploy_token.revoked).to eq(false)

      expect { subject }.to change { deploy_token.reload.revoked }.to eq(true)
    end

    context 'invalid token id' do
      let(:deploy_token_params) { { token_id: non_existing_record_id } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
