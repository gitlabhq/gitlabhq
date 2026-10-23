# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController, :with_current_organization, feature_category: :system_access do
  let_it_be(:user, freeze: false) { create(:user, organizations: [current_organization]) }
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

  describe 'POST #create' do
    context 'with dynamic OAuth application' do
      let_it_be(:application) { create(:oauth_application, :dynamic, redirect_uri: 'http://example.com') }

      context 'when code_challenge is missing' do
        it 'returns 200 and renders error view with PKCE error' do
          post oauth_authorization_path, params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/error')
          expect(response.body).to include('PKCE code_challenge is required for dynamic OAuth applications')
        end
      end

      context 'when code_challenge is present' do
        it 'allows the request to proceed past PKCE validation' do
          post oauth_authorization_path,
            params: params.merge(code_challenge: 'valid_code_challenge', code_challenge_method: 'S256')

          expect(response.body).not_to include('PKCE code_challenge is required')
        end
      end
    end

    context 'with non-dynamic OAuth application' do
      let_it_be(:application) { create(:oauth_application, redirect_uri: 'http://example.com') }

      context 'when code_challenge is missing' do
        it 'does not enforce PKCE validation' do
          post oauth_authorization_path, params: params

          expect(response.body).not_to include('PKCE')
        end
      end
    end

    context 'when stamping the authorizing user onto the application name' do
      context 'with a dynamic (DCR) application' do
        let_it_be_with_reload(:application) do
          create(:oauth_application, :dynamic,
            name: '[Unverified Dynamic Application] kiro',
            scopes: 'mcp',
            redirect_uri: 'http://example.com')
        end

        let(:params) do
          {
            client_id: application.uid,
            response_type: 'code',
            scope: 'mcp',
            redirect_uri: application.redirect_uri,
            state: SecureRandom.hex,
            code_challenge: 'code_challenge_value_abcdefghijklmnop',
            code_challenge_method: 'S256'
          }
        end

        it 'appends the authorizing user to the name', :aggregate_failures do
          post oauth_authorization_path, params: params

          expect(response).to have_gitlab_http_status(:found)
          expect(application.reload.name)
            .to eq("[Unverified Dynamic Application] kiro — authorized by @#{user.username}")
        end

        it 'stamps the user only once across repeat authorizations' do
          2.times { post oauth_authorization_path, params: params.merge(state: SecureRandom.hex) }

          expect(application.reload.name)
            .to eq("[Unverified Dynamic Application] kiro — authorized by @#{user.username}")
        end

        it 'does not stamp the name when the user denies authorization' do
          expect { delete oauth_authorization_path, params: params }
            .not_to change { application.reload.name }.from('[Unverified Dynamic Application] kiro')
        end

        context 'when authorization is not granted (error redirect, no code)' do
          let(:params) { super().merge(response_type: 'token') }

          it 'does not stamp the name' do
            expect { post oauth_authorization_path, params: params }
              .not_to change { application.reload.name }.from('[Unverified Dynamic Application] kiro')
          end
        end

        context 'when the authorizing username contains unsafe characters' do
          let(:unsafe_user) { create(:user, organizations: [current_organization]) }

          before do
            # Bypass username validation to simulate a value the sanitizer must clean.
            unsafe_user.update_column(:username, 'ev.il name<script>')
            sign_in(unsafe_user)
          end

          it 'strips characters outside the safe set before saving' do
            post oauth_authorization_path, params: params

            expect(application.reload.name)
              .to eq('[Unverified Dynamic Application] kiro — authorized by @ev.ilnamescript')
          end
        end
      end

      context 'with a non-dynamic application' do
        let_it_be_with_reload(:application) do
          create(:oauth_application,
            name: 'Instance App',
            scopes: 'read_user',
            redirect_uri: 'http://example.com')
        end

        let(:params) do
          {
            client_id: application.uid,
            response_type: 'code',
            scope: 'read_user',
            redirect_uri: application.redirect_uri,
            state: SecureRandom.hex
          }
        end

        it 'does not modify the application name' do
          expect { post oauth_authorization_path, params: params }
            .not_to change { application.reload.name }.from('Instance App')
        end
      end
    end
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

        expect(request.env['rack.session.options'][:redis_expiry]).to eq(
          Settings.gitlab['unauthenticated_session_expire_delay']
        )

        expect(request.session['user_return_to']).to eq("/oauth/authorize?#{params.to_query}")
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PKCE validation for dynamic applications' do
      context 'with non-dynamic OAuth applications' do
        context 'when an owner is defined' do
          let_it_be(:application) { create(:oauth_application, redirect_uri: 'http://example.com') }

          context 'when code_challenge is missing' do
            it 'does not enforce PKCE validation' do
              get oauth_authorization_path, params: params

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template('doorkeeper/authorizations/new')
              expect(response.body).not_to include('PKCE')
            end
          end
        end

        context 'with application that is explicitly not dynamic' do
          let_it_be(:application) do
            create(:oauth_application, :without_owner, redirect_uri: 'http://example.com')
          end

          context 'when code_challenge is missing' do
            it 'does not enforce PKCE validation' do
              get oauth_authorization_path, params: params

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template('doorkeeper/authorizations/new')
              expect(response.body).not_to include('PKCE')
            end
          end
        end
      end

      context 'with dynamic OAuth application' do
        let_it_be(:application) { create(:oauth_application, :dynamic, redirect_uri: 'http://example.com') }

        context 'when code_challenge is missing' do
          it 'returns 200 and renders error view with PKCE error' do
            get oauth_authorization_path, params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/error')
            expect(response.body).to include('PKCE code_challenge is required for dynamic OAuth applications')
          end
        end

        context 'when code_challenge is blank' do
          it 'returns 200 and renders error view with PKCE error' do
            get oauth_authorization_path, params: params.merge(code_challenge: '')

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/error')
            expect(response.body).to include('PKCE code_challenge is required for dynamic OAuth applications')
          end
        end

        context 'when SHA-256 code_challenge is present' do
          it 'allows the request to proceed past PKCE validation' do
            get oauth_authorization_path,
              params: params.merge(code_challenge: 'valid_code_challenge', code_challenge_method: 'S256')

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/new')
            expect(response.body).not_to include('PKCE code_challenge is required')
          end
        end

        context 'when plain code_challenge is present' do
          it 'returns 200 and renders error view with PKCE error' do
            get oauth_authorization_path,
              params: params.merge(code_challenge: 'valid_code_challenge', code_challenge_method: 'plain')

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/error')
            expect(response.body).to include('there are no accepted code_challenge_method values')
          end
        end
      end
    end

    describe 'MCP server usage with resource params' do
      context 'when resource param ends with /api/v4/mcp' do
        it 'forces scope to mcp regardless of original scope param' do
          get oauth_authorization_path, params: params.merge(
            resource: 'https://gitlab.example.com/api/v4/mcp',
            scope: 'read_user'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp"')
          expect(response.body).not_to include('value="read_user"')
        end

        context 'when scope param is not present' do
          it 'defaults scope to mcp', :aggregate_failures do
            get oauth_authorization_path, params: params.merge(
              resource: 'https://gitlab.example.com/api/v4/mcp'
            ).except(:scope)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/new')
            expect(response.body).to include('value="mcp"')
          end
        end
      end

      context 'when resource param ends with /api/v4/orbit/mcp' do
        it 'forces scope to mcp_orbit regardless of original scope param' do
          get oauth_authorization_path, params: params.merge(
            resource: 'https://gitlab.example.com/api/v4/orbit/mcp',
            scope: 'read_user'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp_orbit"')
          expect(response.body).not_to include('value="read_user"')
        end

        context 'when scope param is not present' do
          it 'defaults scope to mcp_orbit', :aggregate_failures do
            get oauth_authorization_path, params: params.merge(
              resource: 'https://gitlab.example.com/api/v4/orbit/mcp'
            ).except(:scope)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/new')
            expect(response.body).to include('value="mcp_orbit"')
          end
        end
      end

      context 'when resource param does not end with /api/v4/mcp' do
        it 'does not force scope to mcp' do
          get oauth_authorization_path, params: params.merge(
            resource: 'https://gitlab.example.com/api/v4/projects',
            scope: 'read_user'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="read_user"')
          expect(response.body).not_to include('value="mcp"')
        end

        it 'does not force scope when resource ends with different path' do
          get oauth_authorization_path, params: params.merge(
            resource: 'https://gitlab.example.com/api/v4/user',
            scope: 'api'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="api"')
          expect(response.body).not_to include('value="mcp"')
        end
      end

      context 'when resource param is not present' do
        it 'uses the original scope param' do
          get oauth_authorization_path, params: params.merge(scope: 'read_user')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="read_user"')
          expect(response.body).not_to include('value="mcp"')
        end
      end
    end

    describe 'MCP scope forcing for dynamic applications' do
      context 'when dynamic application has only mcp scope and no scope provided' do
        let(:application) { create(:oauth_application, :dynamic, scopes: 'mcp', redirect_uri: 'http://example.com') }

        it 'forces scope to mcp', :aggregate_failures do
          get oauth_authorization_path, params: params.except(:scope).merge(
            code_challenge: 'valid_code_challenge',
            code_challenge_method: 'S256'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp"')
        end
      end

      context 'when dynamic application has only mcp scope and other scopes are requested' do
        let(:application) { create(:oauth_application, :dynamic, scopes: 'mcp', redirect_uri: 'http://example.com') }
        let(:all_scopes) do
          %w[
            api read_api read_user create_runner manage_runner k8s_proxy self_rotate mcp
            read_repository write_repository read_virtual_registry write_virtual_registry
            read_observability write_observability ai_features sudo admin_mode read_service_ping
            openid profile email ai_workflows
          ].join(' ')
        end

        it 'forces scope to mcp regardless of requested scopes', :aggregate_failures do
          get oauth_authorization_path, params: params.merge(
            scope: all_scopes,
            code_challenge: 'valid_code_challenge',
            code_challenge_method: 'S256'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp"')
          expect(response.body).not_to include('value="api"', 'value="read_api"')
        end
      end

      context 'when dynamic application has only mcp_orbit scope and both MCP scopes are requested' do
        let(:application) do
          create(:oauth_application, :dynamic, scopes: 'mcp_orbit', redirect_uri: 'http://example.com')
        end

        it 'forces scope to mcp_orbit', :aggregate_failures do
          get oauth_authorization_path, params: params.merge(
            scope: 'mcp mcp_orbit',
            resource: 'https://gitlab.example.com/api/v4/orbit/mcp',
            code_challenge: 'valid_code_challenge',
            code_challenge_method: 'S256'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp_orbit"')
        end
      end

      context 'when non-dynamic application has multiple scopes and no scope provided' do
        let(:application) { create(:oauth_application, scopes: 'api read_user', redirect_uri: 'http://example.com') }

        it 'does not force to mcp scope', :aggregate_failures do
          get oauth_authorization_path, params: params.except(:scope)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="api read_user"')
        end
      end
    end
  end

  describe 'missing client when dynamic client registration is disabled' do
    let(:docs_anchor) { 'reuse-a-single-oauth-application' }
    let(:params) do
      {
        client_id: client_id,
        response_type: 'code',
        scope: 'api',
        redirect_uri: 'http://example.com',
        state: SecureRandom.hex,
        code_challenge: 'a-valid-code-challenge-that-is-long-enough-1234',
        code_challenge_method: 'S256'
      }
    end

    context 'when dynamic client registration is disabled' do
      before do
        stub_application_setting(dynamic_client_registration_enabled: false)
      end

      context 'and the client_id does not reference any application' do
        let(:client_id) { 'this-client-id-does-not-exist' }

        it 'renders an actionable error linking to the docs', :aggregate_failures do
          get oauth_authorization_path

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/error')
          expect(response.body).to include('dynamic client registration is disabled')
          expect(response.body).to include(docs_anchor)
        end
      end

      context 'and the client_id references an existing application' do
        let(:client_id) { application.uid }

        it 'does not render the custom error' do
          get oauth_authorization_path

          expect(response.body).not_to include(docs_anchor)
        end
      end
    end

    context 'when dynamic client registration is enabled' do
      let(:client_id) { 'this-client-id-does-not-exist' }

      before do
        stub_application_setting(dynamic_client_registration_enabled: true)
      end

      it 'does not render the custom error' do
        get oauth_authorization_path

        expect(response.body).not_to include(docs_anchor)
      end
    end
  end

  describe 'organization maintenance mode enforcement', :without_current_organization do
    let_it_be_with_reload(:organization) { create(:organization) }
    let_it_be(:user, freeze: false) { create(:user, organization: organization) }

    before do
      sign_in(user)
    end

    subject(:request) { get oauth_authorization_path }

    it_behaves_like 'a controller request enforcing organization maintenance mode'
  end

  describe 'granular applications' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:application) do
      create(:oauth_application, :granular, scopes: 'api', redirect_uri: 'http://example.com',
        boundary: Authz::Boundary.for(group), permissions: :read_group)
    end

    let(:params) do
      {
        client_id: application.uid,
        response_type: 'code',
        scope: 'api',
        redirect_uri: application.redirect_uri,
        state: SecureRandom.hex
      }
    end

    def active_grant
      Authz::OauthConsentGrant.active_for_user_and_application(user.id, application.id)
    end

    def latest_code
      OauthAccessGrant.where(resource_owner_id: user.id, application_id: application.id).order(:id).last
    end

    def stub_failing_consent_service
      allow_next_instance_of(Authz::OauthConsentGrants::CreateService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'boom', reason: :invalid))
      end
    end

    describe 'GET #new' do
      it 'forces the granular scope on the consent screen without recording a grant', :aggregate_failures do
        get oauth_authorization_path, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/new')
        expect(response.body).to include('value="granular"')
        expect(response.body).not_to include('value="api"')
        expect(active_grant).to be_nil
      end

      it 'prefers the granular scope over the MCP scope' do
        get oauth_authorization_path, params: params.merge(resource: 'https://gitlab.example.com/api/v4/mcp')

        expect(response.body).to include('value="granular"')
        expect(response.body).not_to include('value="mcp"')
      end

      context 'when the application is trusted' do
        before do
          application.update!(trusted: true)
        end

        it 'records a trusted auto-grant with the declared scopes and redirects', :aggregate_failures do
          expect { get oauth_authorization_path, params: params }.to change { Authz::OauthConsentGrant.count }.by(1)

          expect(response).to render_template('doorkeeper/authorizations/redirect')
          expect(active_grant).to be_trusted_auto_grant
          expect(active_grant.granular_scopes)
            .to contain_exactly(have_attributes(namespace: group, permissions: ['read_group']))
          expect(latest_code.scopes.to_a).to eq(['granular'])
        end

        it 'reuses the active grant on later authorizations' do
          create(:oauth_consent_grant, user: user, application: application, source: :trusted_auto_grant)

          expect { get oauth_authorization_path, params: params }.not_to change { Authz::OauthConsentGrant.count }

          expect(response).to render_template('doorkeeper/authorizations/redirect')
        end

        it 'renders an error when the grant cannot be recorded', :aggregate_failures do
          stub_failing_consent_service

          expect { get oauth_authorization_path, params: params }.not_to change { OauthAccessGrant.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response).to render_template('doorkeeper/authorizations/error')
          expect(response.body).to include(I18n.t('doorkeeper.errors.messages.granular_consent_failed'))
        end
      end

      context 'with a matching granular token for a confidential application' do
        before do
          create(:oauth_access_token, :granular, resource_owner: user, application: application)
        end

        it 'shows the consent screen when no active grant exists' do
          get oauth_authorization_path, params: params

          expect(response).to render_template('doorkeeper/authorizations/new')
        end

        it 'skips the consent screen when an active grant exists' do
          create(:oauth_consent_grant, user: user, application: application)

          get oauth_authorization_path, params: params

          expect(response).to render_template('doorkeeper/authorizations/redirect')
        end
      end

      context 'when the granular_oauth_tokens feature flag is disabled' do
        before do
          stub_feature_flags(granular_oauth_tokens: false)
        end

        it 'keeps the requested legacy scope and records no consent grant', :aggregate_failures do
          expect { get oauth_authorization_path, params: params }.not_to change { Authz::OauthConsentGrant.count }

          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="api"')
          expect(response.body).not_to include('value="granular"')
        end
      end
    end

    describe 'POST #create' do
      it 'records a doorkeeper grant copying the declared scopes and issues a granular code', :aggregate_failures do
        post oauth_authorization_path, params: params

        expect(response).to have_gitlab_http_status(:found)
        expect(active_grant).to be_doorkeeper
        expect(active_grant.granular_scopes).to contain_exactly(
          have_attributes(namespace: group, permissions: ['read_group'], organization_id: user.organization_id)
        )
        expect(latest_code.scopes.to_a).to eq(['granular'])
        expect(response.location).to include("code=#{latest_code.plaintext_token}")
      end

      it 'replaces the active grant on a new consent' do
        previous_grant = create(:oauth_consent_grant, user: user, application: application)

        post oauth_authorization_path, params: params

        expect(Authz::OauthConsentGrant.exists?(previous_grant.id)).to be(false)
        expect(active_grant).not_to eq(previous_grant)
      end

      context 'when the grant cannot be recorded' do
        before do
          stub_failing_consent_service
        end

        it 'renders an error and issues no code', :aggregate_failures do
          expect { post oauth_authorization_path, params: params }.not_to change { OauthAccessGrant.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response).to render_template('doorkeeper/authorizations/error')
          expect(response.body).to include(I18n.t('doorkeeper.errors.messages.granular_consent_failed'))
        end

        it 'does not audit an authorization' do
          expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
            .with(hash_including(name: 'user_authorized_oauth_application'))

          post oauth_authorization_path, params: params
        end
      end

      context 'when the granular_oauth_tokens feature flag is disabled' do
        before do
          stub_feature_flags(granular_oauth_tokens: false)
        end

        it 'issues a legacy code and records no consent grant', :aggregate_failures do
          expect { post oauth_authorization_path, params: params }.not_to change { Authz::OauthConsentGrant.count }

          expect(response).to have_gitlab_http_status(:found)
          expect(latest_code.scopes.to_a).to eq(['api'])
        end
      end
    end
  end
end
