# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DependencyProxyAuthenticationService, feature_category: :virtual_registry do
  let_it_be(:user) { create(:user) }

  let(:params) { {} }
  let(:authentication_abilities) { [] }
  let(:service) { described_class.new(nil, user, params) }

  before do
    stub_config(dependency_proxy: { enabled: true }, registry: { enabled: true })
  end

  describe '#execute' do
    let(:expected_log) do
      {
        message: described_class::MISSING_ABILITIES_MESSAGE,
        username: user.username,
        user_id: user.id,
        authentication_abilities: authentication_abilities
      }
    end

    subject { service.execute(authentication_abilities: authentication_abilities) }

    shared_examples 'returning' do |status:, message:|
      it "returns #{message}", :aggregate_failures do
        expect(subject[:http_status]).to eq(status)
        expect(subject[:message]).to eq(message)
      end
    end

    shared_examples 'returning a token with an encoded field' do |field|
      it 'returns a token with encoded field' do
        token = subject[:token]
        expect(token).not_to be_nil

        decoded_token = decode(token)
        expect(decoded_token[field]).not_to be_nil
      end
    end

    shared_examples 'a token with sufficient authentication abilities' do |token_type:|
      [described_class::REQUIRED_CI_ABILITIES,
        described_class::REQUIRED_USER_ABILITIES,
        described_class::REQUIRED_USER_VR_ABILITIES].each do |abilities|
        context "with #{abilities}" do
          let(:authentication_abilities) { abilities }

          it_behaves_like 'returning a token with an encoded field', token_type
        end
      end
    end

    context 'dependency proxy is not enabled' do
      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it_behaves_like 'returning', status: 404, message: 'dependency proxy not enabled'
    end

    context 'without a user' do
      let(:user) { nil }

      it_behaves_like 'returning', status: 403, message: 'access forbidden'
    end

    context 'with a project deploy token' do
      let_it_be(:project_deploy_token) { create(:deploy_token, :project, :dependency_proxy_scopes) }

      let(:params) { { deploy_token: project_deploy_token } }
      let(:user) { nil }

      it_behaves_like 'returning', status: 403, message: 'access forbidden'

      [described_class::REQUIRED_CI_ABILITIES,
        described_class::REQUIRED_USER_ABILITIES,
        described_class::REQUIRED_USER_VR_ABILITIES].each do |abilities|
        context "with #{abilities}" do
          let(:authentication_abilities) { abilities }

          it_behaves_like 'returning', status: 403, message: 'access forbidden'
        end
      end
    end

    context 'with a group deploy token' do
      let_it_be(:group_deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }

      let(:params) { { deploy_token: group_deploy_token } }
      let(:user) { nil }

      it_behaves_like 'returning', status: 403, message: 'access forbidden'

      it_behaves_like 'a token with sufficient authentication abilities', token_type: 'deploy_token'

      context 'when the the deploy token is restricted with external_authorization' do
        before do
          allow(Gitlab::ExternalAuthorization).to receive(:allow_deploy_tokens_and_deploy_keys?).and_return(false)
        end

        it_behaves_like 'returning', status: 403, message: 'access forbidden'
      end
    end

    context 'with a human user' do
      context 'without the required abilities' do
        it_behaves_like 'returning', status: 403, message: 'access forbidden'
      end

      context 'with the required abilities' do
        let(:authentication_abilities) { described_class::REQUIRED_USER_ABILITIES }

        it_behaves_like 'returning a token with an encoded field', 'user_id'

        context "when the deploy token is restricted with external_authorization" do
          before do
            allow(Gitlab::ExternalAuthorization).to receive(:allow_deploy_tokens_and_deploy_keys?).and_return(false)
          end

          it_behaves_like 'returning a token with an encoded field', 'user_id'
        end
      end
    end

    context 'with a personal access token user' do
      let_it_be_with_reload(:token) { create(:personal_access_token, user: user) }
      let(:params) { { raw_token: token.token } }

      context 'with insufficient authentication abilities' do
        it_behaves_like 'returning', status: 403, message: 'access forbidden'
      end

      it_behaves_like 'a token with sufficient authentication abilities', token_type: 'personal_access_token'
    end

    context 'with a group access token' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:group) { create(:group) }
      let_it_be_with_reload(:token) { create(:personal_access_token, user: user) }

      let(:params) { { raw_token: token.token } }

      before_all do
        group.add_guest(user)
      end

      context 'with insufficient authentication abilities' do
        it_behaves_like 'returning', status: 403, message: 'access forbidden'
      end

      it_behaves_like 'a token with sufficient authentication abilities', token_type: 'group_access_token'
    end

    context 'all other user types' do
      User::USER_TYPES.except(:human, :project_bot).each_value do |user_type|
        context "with user_type #{user_type}" do
          let_it_be_with_reload(:token) { create(:personal_access_token, user: user) }

          before do
            user.update!(user_type: user_type)
          end

          it_behaves_like 'returning', status: 403, message: 'access forbidden'

          it_behaves_like 'a token with sufficient authentication abilities', token_type: 'user_id'
        end
      end
    end

    def decode(token)
      DependencyProxy::AuthTokenService.new(token).execute
    end
  end
end
