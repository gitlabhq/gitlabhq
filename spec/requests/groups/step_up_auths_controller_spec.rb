# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::StepUpAuthsController, type: :controller, feature_category: :system_access do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  let(:oidc_provider_name) { 'openid_connect' }

  let(:oidc_provider_config) do
    GitlabSettings::Options.new(
      name: oidc_provider_name,
      step_up_auth: {
        namespace: {
          id_token: {
            required: { acr: 'gold' }
          }
        }
      }
    )
  end

  before do
    sign_in(user)

    stub_omniauth_setting(enabled: true, providers: [oidc_provider_config])
    allow(Devise).to receive(:omniauth_providers).and_return([oidc_provider_name])

    group.namespace_settings.update!(step_up_auth_required_oauth_provider: oidc_provider_name)
  end

  describe 'GET #new' do
    render_views false

    subject(:make_request) { get :new, params: { group_id: group.to_param } }

    context 'when user is not authenticated' do
      before do
        sign_out(user)
      end

      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authenticated' do
      it 'renders new step-up auth page when step-up auth has not succeeded' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
        end

        it 'renders new step-up auth page because step-up auth has not succeeded' do
          make_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when group has no step-up auth provider configured' do
        before do
          group.namespace_settings.update!(step_up_auth_required_oauth_provider: nil)
        end

        it 'renders new step-up auth page because step-up auth has not succeeded' do
          make_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when step-up auth already succeeded with the correct provider' do
        before do
          session[:omniauth_step_up_auth] = {
            oidc_provider_name => { 'namespace' => { 'state' => 'succeeded' } }
          }
        end

        it 'redirects with notice' do
          make_request

          expect(response).to redirect_to(group_path(group))
          expect(flash[:notice]).to eq('Step-up authentication already completed')
        end
      end

      context 'with multiple OAuth providers configured' do
        let(:another_provider_name) { 'keycloak2' }

        let(:another_provider_config) do
          GitlabSettings::Options.new(
            name: another_provider_name,
            step_up_auth: {
              namespace: {
                id_token: {
                  required: { acr: 'silver' }
                }
              }
            }
          )
        end

        before do
          stub_omniauth_setting(enabled: true, providers: [oidc_provider_config, another_provider_config])
          allow(Devise).to receive(:omniauth_providers).and_return([oidc_provider_name, another_provider_name])
        end

        context 'when step-up auth succeeded with a different provider than required' do
          before do
            session[:omniauth_step_up_auth] = {
              another_provider_name => { 'namespace' => { 'state' => 'succeeded' } }
            }
          end

          it 'stays on the step-up auth page instead of redirecting' do
            make_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).not_to redirect_to(group_path(group))
          end
        end

        context 'when step-up auth succeeded with the correct provider' do
          before do
            session[:omniauth_step_up_auth] = {
              oidc_provider_name => { 'namespace' => { 'state' => 'succeeded' } }
            }
          end

          it 'redirects to the group page' do
            make_request

            expect(response).to redirect_to(group_path(group))
            expect(flash[:notice]).to eq('Step-up authentication already completed')
          end
        end
      end
    end
  end
end
