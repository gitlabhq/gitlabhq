# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Registrations::ProfilesController, feature_category: :onboarding do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET /admin/registrations/profile/new' do
    subject(:get_new) { get new_admin_registrations_profile_path }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(self_managed_welcome_onboarding: false)
        sign_in(admin)
      end

      it 'returns not found', :enable_admin_mode do
        get_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when on a Dedicated instance' do
      before do
        stub_application_setting(gitlab_dedicated_instance: true)
        sign_in(admin)
      end

      it 'returns not found', :enable_admin_mode do
        get_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature flag is enabled' do
      context 'with an unauthenticated user' do
        it 'redirects to sign in' do
          get_new

          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'with a non-admin user' do
        before do
          sign_in(regular_user)
        end

        it 'returns not found' do
          get_new

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when admin mode is not enabled' do
        before do
          sign_in(admin)
        end

        it 'redirects to admin mode login' do
          get_new

          expect(response).to redirect_to(new_admin_session_path)
        end
      end

      context 'with an admin user', :enable_admin_mode do
        before do
          sign_in(admin)
        end

        it 'returns ok' do
          get_new

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'tracks the view event' do
          expect { get_new }
            .to trigger_internal_events('view_setup_profile_page')
            .with(user: admin, additional_properties: {})
        end
      end
    end
  end

  describe 'PATCH /admin/registrations/profile' do
    let(:user_params) do
      {
        first_name: 'Jane',
        last_name: 'Doe',
        email: admin.email,
        user_detail_attributes: { company: 'Acme Corp' }
      }
    end

    subject(:patch_update) do
      patch admin_registrations_profile_path, params: { user: user_params }
    end

    context 'with an unauthenticated user' do
      it 'redirects to sign in' do
        patch_update

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with a non-admin user' do
      before do
        sign_in(regular_user)
      end

      it 'returns not found' do
        patch_update

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when :self_managed_welcome_onboarding is disabled' do
      before do
        stub_feature_flags(self_managed_welcome_onboarding: false)
        sign_in(admin)
      end

      it 'returns not found', :enable_admin_mode do
        patch_update

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an admin user', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      context 'with valid params' do
        it 'updates the user profile' do
          expect { patch_update }.to change { admin.reload.first_name }.to('Jane')
            .and change { admin.reload.last_name }.to('Doe')
            .and change { admin.reload.name }.to('Jane Doe')
        end

        it 'updates the organization name' do
          expect { patch_update }.to change { admin.reload.user_detail.company }.to('Acme Corp')
        end

        it 'tracks the submit event with success label' do
          expect { patch_update }
            .to trigger_internal_events('submit_setup_profile_form')
            .with(user: admin, additional_properties: { label: 'success' })
        end

        context 'when a project id is in the session' do
          let_it_be(:project) { create(:project) }

          before do
            allow_next_instance_of(described_class) do |controller|
              allow(controller).to receive(:pop_welcome_project_id).and_return(project.id)
            end
          end

          it 'redirects to the project' do
            patch_update

            expect(response).to redirect_to(project_path(project))
          end
        end

        context 'when no project id is in the session' do
          it 'redirects to root' do
            patch_update

            expect(response).to redirect_to(root_path)
          end
        end
      end

      context 'with invalid params' do
        let(:user_params) { { first_name: 'a' * 128, last_name: 'Doe', email: admin.email } }

        it 're-renders the form with unprocessable_entity status' do
          patch_update

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'tracks the submit event with error label' do
          expect { patch_update }
            .to trigger_internal_events('submit_setup_profile_form')
            .with(user: admin, additional_properties: { label: 'error' })
        end

        it 'does not track the view event on re-render' do
          expect { patch_update }.not_to trigger_internal_events('view_setup_profile_page')
        end
      end

      context 'when the update service fails' do
        before do
          allow_next_instance_of(::Users::UpdateService) do |service|
            allow(service).to receive(:execute).and_return({ status: :error, message: 'oops' })
          end
        end

        it 're-renders the form' do
          patch_update

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'tracks the submit event with error label' do
          expect { patch_update }
            .to trigger_internal_events('submit_setup_profile_form')
            .with(user: admin, additional_properties: { label: 'error' })
        end

        it 'does not track the view event on re-render' do
          expect { patch_update }.not_to trigger_internal_events('view_setup_profile_page')
        end
      end
    end
  end

  describe 'GET /admin/registrations/profile/skip' do
    subject(:get_skip) { get skip_admin_registrations_profile_path }

    context 'with an admin user', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      context 'when a project id is in the session' do
        let_it_be(:project) { create(:project) }

        before do
          allow_next_instance_of(described_class) do |controller|
            allow(controller).to receive(:pop_welcome_project_id).and_return(project.id)
          end
        end

        it 'redirects to the project' do
          get_skip

          expect(response).to redirect_to(project_path(project))
        end
      end

      context 'when no project id is in the session' do
        it 'redirects to root' do
          get_skip

          expect(response).to redirect_to(root_path)
        end
      end

      it 'tracks the skip event' do
        expect { get_skip }
          .to trigger_internal_events('click_skip_setup_profile')
          .with(user: admin)
      end
    end
  end
end
