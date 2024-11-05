# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::RevokeService, feature_category: :deployment_management do
  let_it_be(:entity) { create(:project) }
  let_it_be(:deploy_token) { create(:deploy_token, projects: [entity]) }
  let_it_be(:deploy_token_params) { { id: deploy_token.id } }

  describe '#execute' do
    subject(:revoke_service) do
      described_class.new(project: entity, current_user: user, params: deploy_token_params).execute
    end

    context 'as admin' do
      let(:user) { create(:admin) }

      context 'when admin mode enabled', :enable_admin_mode do
        it 'revokes a project deploy token' do
          expect(deploy_token.revoked).to be_falsey
          expect { revoke_service }.to change { deploy_token.reload.revoked }.to be_truthy
        end

        context 'when the token id is invalid' do
          let(:deploy_token_params) { { token_id: non_existing_record_id } }

          it 'returns an error' do
            expect(revoke_service.status).to eq(:error)
          end
        end
      end

      context 'when admin mode disabled' do
        it 'returns an error' do
          expect(revoke_service.status).to eq(:error)
        end

        it 'does not revoke the token' do
          revoke_service
          expect(deploy_token.reload.revoked).to be_falsey
        end
      end
    end

    context 'as a user' do
      let(:user) { create(:user) }

      it 'does not revoke a project deploy token' do
        expect(revoke_service.status).to eq(:error)
      end

      it 'does not revoke the token' do
        revoke_service
        expect(deploy_token.reload.revoked).to be_falsey
      end
    end
  end
end
