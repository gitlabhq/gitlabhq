# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DependencyProxyAuthenticationService, feature_category: :dependency_proxy do
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }

  let(:authentication_abilities) { nil }
  let(:service) { described_class.new(nil, user, params) }

  before do
    stub_config(dependency_proxy: { enabled: true }, registry: { enabled: true })
  end

  describe '#execute' do
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

    context 'with a deploy token' do
      let_it_be(:deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }
      let_it_be(:params) { { deploy_token: deploy_token } }

      it_behaves_like 'returning a token with an encoded field', 'deploy_token'
    end

    context 'with a human user' do
      it_behaves_like 'returning a token with an encoded field', 'user_id'
    end

    context 'all other user types' do
      User::USER_TYPES.except(:human, :project_bot).each_value do |user_type|
        context "with user_type #{user_type}" do
          before do
            user.update!(user_type: user_type)
          end

          it_behaves_like 'returning a token with an encoded field', 'user_id'
        end
      end
    end

    context 'with a group access token' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be_with_reload(:token) { create(:personal_access_token, user: user) }

      context 'with insufficient authentication abilities' do
        it_behaves_like 'returning', status: 403, message: 'access forbidden'

        context 'packages_dependency_proxy_containers_scope_check disabled' do
          before do
            stub_feature_flags(packages_dependency_proxy_containers_scope_check: false)
          end

          it_behaves_like 'returning a token with an encoded field', 'user_id'
        end
      end

      context 'with sufficient authentication abilities' do
        let_it_be(:authentication_abilities) { Auth::DependencyProxyAuthenticationService::REQUIRED_ABILITIES }
        let_it_be(:params) { { raw_token: token.token } }

        subject { service.execute(authentication_abilities: authentication_abilities) }

        it_behaves_like 'returning a token with an encoded field', 'user_id'

        context 'revoked' do
          before do
            token.revoke!
          end

          it_behaves_like 'returning', status: 403, message: 'access forbidden'
        end

        context 'expired' do
          before do
            token.update_column(:expires_at, 1.day.ago)
          end

          it_behaves_like 'returning', status: 403, message: 'access forbidden'
        end
      end
    end

    def decode(token)
      DependencyProxy::AuthTokenService.new(token).execute
    end
  end
end
