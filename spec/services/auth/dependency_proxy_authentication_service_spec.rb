# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DependencyProxyAuthenticationService, feature_category: :dependency_proxy do
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }

  let(:service) { described_class.new(nil, user, params) }

  before do
    stub_config(dependency_proxy: { enabled: true }, registry: { enabled: true })
  end

  describe '#execute' do
    subject { service.execute(authentication_abilities: nil) }

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

    def decode(token)
      DependencyProxy::AuthTokenService.new(token).execute
    end
  end
end
