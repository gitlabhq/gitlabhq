# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver, feature_category: :system_access do
  let(:resolver) { described_class.new(request, session) }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:session) { {} }
  let(:group) { create(:group) }
  let(:query_parameters) { {} }

  before do
    allow(resolver).to receive(:new_user_session_url).and_return('/login')
    allow(request).to receive(:query_parameters).and_return(query_parameters)
  end

  describe '#resolve_redirect_url' do
    subject(:resolve_redirect_url) { resolver.resolve_redirect_url }

    context 'with any namespace id' do
      let(:query_parameters) { { 'root_namespace_id' => group.id } }

      it 'returns new_user_session_url' do
        expect(resolver).to receive(:new_user_session_url)
        expect(resolve_redirect_url).to eq('/login')
      end
    end

    context 'with nil namespace id' do
      let(:query_parameters) { { 'root_namespace_id' => nil } }

      it 'returns new_user_session_url' do
        expect(resolve_redirect_url).to eq('/login')
      end
    end

    context 'with the ChatGPT connector installation flow' do
      let_it_be(:connector_redirect_uri) { 'https://chatgpt.com/connector_platform_oauth_redirect' }
      let_it_be(:connector_application) do
        create(:oauth_application, :without_owner, redirect_uri: connector_redirect_uri)
      end

      let(:query_parameters) do
        { 'target_flow' => 'chatgpt_siwc', 'client_id' => connector_application.uid,
          'redirect_uri' => connector_redirect_uri }
      end

      before do
        allow(::Gitlab::Auth::OAuth::Provider).to receive(:enabled?).with('chatgpt').and_return(true)
      end

      it 'stores the validated provider in the session and redirects to the login page' do
        expect(resolve_redirect_url).to eq('/login')
        expect(session[::Authn::ProviderSignInRedirect::SESSION_KEY]).to eq('chatgpt')
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(chatgpt_siwc_login_redirect: false)
        end

        it 'returns new_user_session_url without setting the session key' do
          expect(resolve_redirect_url).to eq('/login')
          expect(session).not_to have_key(::Authn::ProviderSignInRedirect::SESSION_KEY)
        end
      end

      context 'when the request does not originate from the connector application' do
        let(:query_parameters) do
          { 'target_flow' => 'chatgpt_siwc', 'client_id' => 'not-the-connector' }
        end

        it 'returns new_user_session_url without setting the session key' do
          expect(resolve_redirect_url).to eq('/login')
          expect(session).not_to have_key(::Authn::ProviderSignInRedirect::SESSION_KEY)
        end
      end
    end

    context 'when target_flow is not chatgpt_siwc' do
      let(:query_parameters) { { 'target_flow' => 'something_else' } }

      it 'returns new_user_session_url' do
        expect(resolve_redirect_url).to eq('/login')
      end
    end
  end
end
