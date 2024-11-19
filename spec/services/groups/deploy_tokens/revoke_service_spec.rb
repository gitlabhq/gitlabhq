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

    it 'returns a successful ServiceResponse' do
      expect(subject).to be_kind_of(ServiceResponse)
      expect(subject.success?).to be_truthy
    end

    context 'invalid token id' do
      let(:deploy_token_params) { { token_id: non_existing_record_id } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with raising revoke!' do
      before do
        allow(deploy_token).to receive(:revoke!) { raise ActiveRecord::RecordNotSaved }

        tokens = instance_double(ActiveRecord::Relation)
        allow(tokens).to receive(:find).with(deploy_token.id).and_return(deploy_token)
        allow(entity).to receive(:deploy_tokens).and_return(tokens)
      end

      it 'raises error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end
  end
end
