# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController, :with_current_organization, feature_category: :system_access do
  let_it_be(:user) { create(:user, organizations: [current_organization]) }
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'custom://test') }

  let(:params) do
    {
      client_id: application.uid,
      response_type: 'code',
      scope: application.scopes,
      redirect_uri: application.redirect_uri,
      state: SecureRandom.hex
    }
  end

  let(:oauth_authorization_path) { Gitlab::Routing.url_helpers.oauth_authorization_url(params) }

  before do
    sign_in(user)
  end

  describe 'GET #new' do
    it_behaves_like 'Base action controller' do
      subject(:request) { get oauth_authorization_path }
    end

    context 'when application redirect URI has a custom scheme' do
      context 'when CSP is disabled' do
        before do
          allow_next_instance_of(ActionDispatch::Request) do |instance|
            allow(instance).to receive(:content_security_policy).and_return(nil)
          end
        end

        it 'does not add a CSP' do
          get oauth_authorization_path

          expect(response.headers['Content-Security-Policy']).to be_nil
        end
      end

      context 'when CSP contains form-action' do
        before do
          csp = ActionDispatch::ContentSecurityPolicy.new do |p|
            p.form_action "'self'"
          end

          allow_next_instance_of(ActionDispatch::Request) do |instance|
            allow(instance).to receive(:content_security_policy).and_return(csp)
          end
        end

        it 'adds custom scheme to CSP form-action' do
          get oauth_authorization_path

          expect(response.headers['Content-Security-Policy']).to include("form-action 'self' custom:")
        end
      end

      context 'when CSP does not contain form-action' do
        before do
          csp = ActionDispatch::ContentSecurityPolicy.new do |p|
            p.script_src :self, 'https://some-cdn.test'
            p.style_src :self, 'https://some-cdn.test'
          end

          allow_next_instance_of(ActionDispatch::Request) do |instance|
            allow(instance).to receive(:content_security_policy).and_return(csp)
          end
        end

        it 'does not add form-action to the CSP' do
          get oauth_authorization_path

          expect(response.headers['Content-Security-Policy']).not_to include('form-action')
        end
      end
    end

    context 'when the user is not signed in' do
      before do
        sign_out(user)
      end

      it 'sets a lower session expiry and redirects to the sign in page' do
        get oauth_authorization_path

        expect(request.env['rack.session.options'][:expire_after]).to eq(
          Settings.gitlab['unauthenticated_session_expire_delay']
        )

        expect(request.session['user_return_to']).to eq("/oauth/authorize?#{params.to_query}")
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
