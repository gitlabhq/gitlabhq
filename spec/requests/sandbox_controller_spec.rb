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
  end
end
