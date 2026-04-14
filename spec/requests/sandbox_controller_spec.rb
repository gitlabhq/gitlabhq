# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SandboxController, feature_category: :shared do
  shared_examples 'mermaid sandbox endpoint' do |path_helper|
    subject(:get_mermaid) { get send(path_helper) }

    it 'renders page without template' do
      get_mermaid

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(layout: nil)
    end

    context 'with a signed-in user' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'renders page' do
        get_mermaid

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when enforce_terms setting is enabled' do
        before do
          stub_application_setting(enforce_terms: true, require_two_factor_authentication: true)
        end

        it 'does not enforce terms for rendering Mermaid markdown' do
          get_mermaid

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    describe 'Content-Security-Policy' do
      let(:csp_header) { response['Content-Security-Policy'] }
      let(:directives) do
        # This won't work well if any directive has '; ' in it, but practically speaking, none do.
        csp_header.split('; ').to_h { |d| d.split(' ', 2) }
      end

      it 'always includes a CSP header with script-src that blocks inline scripts' do
        get_mermaid

        expect(csp_header).to be_present
        expect(directives['script-src']).to include("'self'")
        expect(directives['script-src']).not_to include("'unsafe-inline'")
      end

      it 'sets restrictive defaults' do
        get_mermaid

        expect(directives['default-src']).to eq("'self'")
        expect(directives['base-uri']).to eq("'self'")
        expect(directives['frame-src']).to eq("'none'")
        expect(directives['object-src']).to eq("'none'")
      end

      context 'with asset proxy disabled' do
        before do
          stub_asset_proxy_setting(enabled: false)
        end

        it 'does not include asset proxy hosts in img-src or media-src' do
          get_mermaid

          expect(directives['img-src']).not_to include("assets.example.com")
          expect(directives['media-src']).not_to include("assets.example.com")
        end
      end

      context 'with asset proxy enabled' do
        before do
          stub_asset_proxy_enabled(
            url: 'https://assets.example.com',
            secret_key: 'shared-secret',
            allowlist: %W[gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}]
          )
        end

        it 'overrides the img-src and media-src CSPs to self, the allowlist, and the asset proxy' do
          get_mermaid

          expect(directives['img-src']).to eq(
            "'self' https://assets.example.com/ http://gitlab.com:* http://*.mydomain.com:* http://localhost:*")
          expect(directives['media-src']).to eq(
            "'self' https://assets.example.com/ http://gitlab.com:* http://*.mydomain.com:* http://localhost:*")
        end
      end
    end
  end

  describe 'GET #swagger' do
    it 'does not set a sandbox-specific CSP' do
      get sandbox_swagger_path

      csp = response['Content-Security-Policy']
      if csp.present?
        directives = csp.split('; ').to_h { |d| d.split(' ', 2) }
        expect(directives['frame-src']).not_to eq("'none'")
      end
    end
  end

  describe 'GET #mermaid_v10' do
    it_behaves_like 'mermaid sandbox endpoint', :sandbox_mermaid_v10_path
  end

  describe 'GET #mermaid_v11' do
    it_behaves_like 'mermaid sandbox endpoint', :sandbox_mermaid_v11_path
  end
end
