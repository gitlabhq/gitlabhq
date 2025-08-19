# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Groups::Observability::O11yServiceSettings", feature_category: :observability do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_without_group_access) { create(:user) }

  before_all do
    group.add_maintainer(user)
  end

  before do
    sign_in(user)
    stub_feature_flags(o11y_settings_access: user)
  end

  def expect_new_settings_built
    expect(assigns(:settings)).to be_a(Observability::GroupO11ySetting)
    expect(assigns(:settings)).to be_new_record
    expect(assigns(:settings).group).to eq(group)
  end

  describe "GET /edit" do
    subject(:edit_request) { get edit_group_observability_o11y_service_settings_path(group) }

    context 'with persisted settings' do
      let_it_be(:settings) { create(:observability_group_o11y_setting, group: group) }

      it 'returns 200' do
        edit_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      it 'assigns @settings' do
        edit_request

        expect(assigns(:settings)).to eq(settings)
      end
    end

    context 'without persisted settings' do
      before do
        group.observability_group_o11y_setting&.destroy!
        group.reload
      end

      it 'builds new settings' do
        edit_request

        expect_new_settings_built
      end
    end

    context 'when feature flags are disabled' do
      before do
        stub_feature_flags(o11y_settings_access: false)
      end

      it 'returns 404' do
        edit_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have group access but has feature flag enabled' do
      before do
        sign_in(user_without_group_access)
        stub_feature_flags(o11y_settings_access: user_without_group_access)
      end

      it 'returns 200 and builds new settings' do
        edit_request
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect_new_settings_built
      end
    end
  end

  describe "PUT /update" do
    let_it_be(:settings) { create(:observability_group_o11y_setting, group: group) }

    let(:valid_params) do
      {
        observability_group_o11y_setting: {
          o11y_service_url: 'https://new-o11y-instance.com',
          o11y_service_user_email: 'newuser@example.com',
          o11y_service_password: 'newpassword',
          o11y_service_post_message_encryption_key: 'new-32-character-encryption-key-here'
        }
      }
    end

    subject(:update_request) { put group_observability_o11y_service_settings_path(group), params: valid_params }

    context 'when updating existing settings' do
      context 'with valid params' do
        it 'updates the settings and redirects with success message' do
          expect_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            expect(service).to receive(:execute).with(
              an_instance_of(Observability::GroupO11ySetting),
              an_instance_of(ActionController::Parameters)
            ).and_wrap_original do
              settings.update!(o11y_service_url: 'https://new-o11y-instance.com')
              ServiceResponse.success(payload: { settings: settings })
            end
          end

          expect { update_request }.to change { settings.reload.o11y_service_url }.to('https://new-o11y-instance.com')

          expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
          expect(flash[:notice]).to eq('Observability service settings updated successfully.')
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            observability_group_o11y_setting: {
              o11y_service_url: '',
              o11y_service_user_email: 'invalid-email',
              o11y_service_password: '',
              o11y_service_post_message_encryption_key: ''
            }
          }
        end

        it 'handles service failure gracefully' do
          allow_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Failed to update settings'))
          end

          put group_observability_o11y_service_settings_path(group), params: invalid_params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
          expect { put group_observability_o11y_service_settings_path(group), params: invalid_params }
            .not_to change { settings.reload.o11y_service_url }
        end
      end

      context 'when service execution fails' do
        it 'renders edit template' do
          allow_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Failed to update settings'))
          end

          update_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
        end
      end
    end

    # Access control tests
    context 'when feature flags are disabled' do
      before do
        stub_feature_flags(o11y_settings_access: false)
      end

      it 'returns 404' do
        update_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have group access but has feature flag enabled' do
      before do
        sign_in(user_without_group_access)
        stub_feature_flags(o11y_settings_access: user_without_group_access)
      end

      it 'allows updating settings' do
        expect_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
          expect(service).to receive(:execute).with(
            an_instance_of(Observability::GroupO11ySetting),
            an_instance_of(ActionController::Parameters)
          ).and_wrap_original do
            settings.update!(o11y_service_url: 'https://new-o11y-instance.com')
            ServiceResponse.success(payload: { settings: settings })
          end
        end

        update_request

        expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
        expect(flash[:notice]).to eq('Observability service settings updated successfully.')
      end
    end
  end

  describe "DELETE /destroy" do
    subject(:destroy_request) { delete group_observability_o11y_service_settings_path(group) }

    context 'with persisted settings' do
      let!(:settings) { create(:observability_group_o11y_setting, group: group) }

      it 'deletes the settings and redirects with success message' do
        expect { destroy_request }.to change { Observability::GroupO11ySetting.count }.by(-1)

        expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
        expect(response).to have_gitlab_http_status(:see_other)
        expect(flash[:notice]).to eq('Observability service settings deleted successfully.')
      end

      context 'when settings.destroy returns false' do
        before do
          allow_next_instance_of(Groups::Observability::O11yServiceSettingsController) do |instance|
            allow(instance).to receive(:settings).and_return(settings)
          end
          allow(settings).to receive(:destroy).and_return(false)
        end

        it 'redirects with error message and does not delete settings' do
          expect { destroy_request }.not_to change { Observability::GroupO11ySetting.count }

          expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
          expect(response).to have_gitlab_http_status(:see_other)
          expect(flash[:alert]).to eq('Failed to delete observability service settings.')
        end
      end

      context 'when settings.destroy raises an exception' do
        before do
          allow_next_instance_of(Groups::Observability::O11yServiceSettingsController) do |instance|
            allow(instance).to receive(:settings).and_return(settings)
          end
          allow(settings).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed.new('Failed to destroy'))
        end

        it 'redirects with error message' do
          destroy_request

          expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
          expect(response).to have_gitlab_http_status(:see_other)
          expect(flash[:alert]).to eq('Failed to delete observability service settings.')
        end
      end
    end

    context 'without persisted settings' do
      before do
        group.observability_group_o11y_setting&.destroy!
        group.reload
      end

      it 'redirects with success message for new record' do
        destroy_request

        expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
        expect(response).to have_gitlab_http_status(:see_other)
        expect(flash[:notice]).to eq('Observability service settings deleted successfully.')
      end
    end

    context 'when feature flags are disabled' do
      before do
        stub_feature_flags(o11y_settings_access: false)
      end

      it 'returns 404' do
        destroy_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have group access but has feature flag enabled' do
      let!(:settings) { create(:observability_group_o11y_setting, group: group) }

      before do
        sign_in(user_without_group_access)
        stub_feature_flags(o11y_settings_access: user_without_group_access)
      end

      it 'allows deleting settings' do
        expect { destroy_request }.to change { Observability::GroupO11ySetting.count }.by(-1)

        expect(response).to redirect_to(edit_group_observability_o11y_service_settings_path(group))
        expect(response).to have_gitlab_http_status(:see_other)
        expect(flash[:notice]).to eq('Observability service settings deleted successfully.')
      end
    end
  end
end
