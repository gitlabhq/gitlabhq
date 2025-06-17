# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::AiCatalogController, feature_category: :duo_workflow do
  let_it_be(:user) { create(:user) }

  describe 'GET #index' do
    let(:path) { explore_ai_catalog_path }

    before do
      stub_feature_flags(global_ai_catalog: true)
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      it 'responds with success' do
        get path

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'renders the index template' do
        get path

        expect(response).to render_template('index')
      end

      it 'uses the explore layout' do
        get path

        expect(response).to render_template(layout: 'explore')
      end
    end

    context 'when user is not signed in' do
      it 'responds with success' do
        get path

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'renders the index template' do
        get path

        expect(response).to render_template('index')
      end

      it 'uses the explore layout' do
        get path

        expect(response).to render_template(layout: 'explore')
      end
    end

    context 'when public visibility is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when user is signed in' do
        before do
          sign_in(user)
        end

        it 'responds with success' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'renders the index template' do
          get path

          expect(response).to render_template('index')
        end
      end

      context 'when user is not signed in' do
        it 'redirects to login page' do
          get path

          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    context 'when global_ai_catalog feature flag is disabled' do
      before do
        stub_feature_flags(global_ai_catalog: false)
      end

      context 'when user is signed in' do
        before do
          sign_in(user)
        end

        it 'renders 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is not signed in' do
        it 'renders 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when global_ai_catalog feature flag is enabled for specific user' do
      let_it_be(:enabled_user) { create(:user) }
      let_it_be(:disabled_user) { create(:user) }

      before do
        stub_feature_flags(global_ai_catalog: enabled_user)
      end

      context 'when enabled user is signed in' do
        before do
          sign_in(enabled_user)
        end

        it 'responds with success' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'renders the index template' do
          get path

          expect(response).to render_template('index')
        end
      end

      context 'when disabled user is signed in' do
        before do
          sign_in(disabled_user)
        end

        it 'renders 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is not signed in' do
        it 'renders 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
