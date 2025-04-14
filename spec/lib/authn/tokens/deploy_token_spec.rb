# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::DeployToken, feature_category: :system_access do
  shared_examples 'valid deploy token' do
    let(:plaintext) { deploy_token.token }
    let(:valid_revocable) { deploy_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(user)).to be_truthy
      end
    end
  end

  let_it_be(:user) { create(:user) }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with group deploy token' do
    let_it_be(:group) { create(:group) }
    let(:group_deploy_token) { create(:group_deploy_token, group: group) }
    let(:deploy_token) { group_deploy_token.deploy_token }

    it_behaves_like 'valid deploy token'

    context 'with group missing' do
      let(:plaintext) { deploy_token.token }

      it 'raises unsupported deploy token type' do
        expect(deploy_token).to receive(:group).and_return(nil)
        expect(::DeployToken).to receive(:find_by_token).with(plaintext).and_return(deploy_token)

        expect do
          token.revoke!(user)
        end
          .to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported deploy token type')
      end
    end
  end

  context 'with valid project deploy token' do
    let_it_be(:project) { create(:project) }
    let_it_be(:project_deploy_token) { create(:project_deploy_token) }
    let_it_be(:deploy_token) { project_deploy_token.deploy_token }

    it_behaves_like 'valid deploy token'

    context 'with project missing' do
      let(:plaintext) { deploy_token.token }

      it 'raises unsupported deploy token type' do
        expect(deploy_token).to receive(:project).and_return(nil)
        expect(::DeployToken).to receive(:find_by_token).with(plaintext).and_return(deploy_token)

        expect do
          token.revoke!(user)
        end
          .to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported deploy token type')
      end
    end

    context 'with custom instance prefix' do
      let_it_be(:instance_prefix) { 'instance-prefix-' }
      let(:valid_revocable) { create(:deploy_token) }
      let(:plaintext) { valid_revocable.token }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'starts with the instance prefix' do
        expect(plaintext).to start_with(instance_prefix)
      end

      it_behaves_like 'finding the valid revocable'

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'starts with the default prefix' do
          expect(plaintext).to start_with(DeployToken::DEPLOY_TOKEN_PREFIX)
        end
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
