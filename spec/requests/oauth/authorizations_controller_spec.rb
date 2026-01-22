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

    describe 'MCP scope defaulting for dynamic applications' do
      context 'when dynamic application has only mcp scope and no scope provided' do
        let(:application) { create(:oauth_application, :dynamic, scopes: 'mcp', redirect_uri: 'http://example.com') }

        it 'defaults scope to mcp', :aggregate_failures do
          get oauth_authorization_path, params: params.except(:scope).merge(
            code_challenge: 'valid_code_challenge',
            code_challenge_method: 'S256'
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="mcp"')
        end
      end

      context 'when non-dynamic application has multiple scopes and no scope provided' do
        let(:application) { create(:oauth_application, scopes: 'api read_user', redirect_uri: 'http://example.com') }

        it 'does not default to mcp scope', :aggregate_failures do
          get oauth_authorization_path, params: params.except(:scope)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
          expect(response.body).to include('value="api read_user"')
        end
      end
    end
  end
end
