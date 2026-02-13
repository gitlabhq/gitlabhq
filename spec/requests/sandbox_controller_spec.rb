# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SandboxController, feature_category: :shared do
  describe 'GET #mermaid' do
    subject(:get_mermaid) { get sandbox_mermaid_path }

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
      let(:directives) do
        # This won't work well if any directive has '; ' in it, but practically speaking, none do.
        response['Content-Security-Policy'].split('; ').group_by { |d| d.split(' ', 2).first }
      end

      context 'with asset proxy disabled' do
        before do
          stub_asset_proxy_setting(enabled: false)
        end

        it 'does not modify the default CSPs for img-src and media-src' do
          get_mermaid

          # Different test environments produce different values for these by default;
          # commonly "'self' data: blob: http: https:", sometimes "* data: blob:",
          # sometimes unset (disabled).  Instead of asserting the exact expected
          # value, assert instead that we haven't inserted the asset proxy host.
          %w[img-src media-src].each do |directive|
            if directives[directive]
              expect(directives[directive].length).to eq(1)
              expect(directives[directive].first).not_to include("assets.example.com")
            end
          end
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
            ["img-src 'self' https://assets.example.com/ http://gitlab.com:* http://*.mydomain.com:* http://localhost:*"])
          expect(directives['media-src']).to eq(
            ["media-src 'self' https://assets.example.com/ http://gitlab.com:* http://*.mydomain.com:* http://localhost:*"])
        end
      end
    end
  end
end
