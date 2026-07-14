# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Projects::Observability::Setup", feature_category: :observability do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:user_namespace) { user.namespace }
  let_it_be(:project) { create(:project, :empty_repo, namespace: user_namespace) }

  before do
    sign_in(user)
  end

  describe "GET /show" do
    subject(:get_setup_page) { get project_observability_setup_path(project, params) }

    let(:params) { {} }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'returns 404' do
        get_setup_page
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: user_namespace)
      end

      it "returns http success and renders the setup page" do
        get_setup_page

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:success)
          expect(response.body).to include('GitLab Observability')
        end
      end

      context 'when project belongs to a group' do
        let_it_be(:group) { create(:group) }
        let_it_be(:group_project) { create(:project, :empty_repo, group: group) }

        before_all do
          group.add_developer(user)
        end

        before do
          stub_feature_flags(observability_sass_features: group)
        end

        it 'redirects to the group setup page' do
          get project_observability_setup_path(group_project)

          expect(response).to redirect_to(group_observability_setup_path(group))
        end
      end

      context 'when namespace already has observability settings' do
        let_it_be(:o11y_setting) { create(:observability_group_o11y_setting, group: user_namespace) }

        it 'returns early without building a new setting' do
          get_setup_page
          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when namespace does not have observability settings' do
        context 'when provisioning parameter is true' do
          let(:params) { { provisioning: 'true' } }

          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          it 'builds observability setting with namespace id as service name' do
            get_setup_page

            expect(response).to have_gitlab_http_status(:success)
          end
        end

        context 'when provisioning parameter is false or not provided' do
          it 'does not build observability setting' do
            get_setup_page

            expect(response).to have_gitlab_http_status(:success)
          end
        end

        context 'when on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          it 'renders the Enable Observability button' do
            get_setup_page

            expect(response.body).to include('Enable Observability')
            expect(response.body).to include(project_observability_access_requests_path(project))
          end

          it 'renders the personal namespace copy' do
            get_setup_page

            expect(response.body).to include('all projects in your personal namespace')
          end
        end

        context 'when not on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(false)
          end

          it 'renders the administrator message instead of the button' do
            get_setup_page

            expect(response.body)
              .to include('please ask your <strong>GitLab administrator</strong> ' \
                'to enable it for this project')
            expect(response.body).not_to include(project_observability_access_requests_path(project))
          end
        end
      end

      context 'without proper permissions' do
        let_it_be(:other_user) { create(:user) }

        before do
          sign_in(other_user)
        end

        it 'returns 404' do
          get_setup_page
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
