# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SlacksController, :enable_admin_mode, feature_category: :integrations do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    stub_application_setting(slack_app_enabled: true)
  end

  def redirect_url
    edit_admin_application_settings_integration_path(
      Integrations::GitlabSlackApplication.to_param
    )
  end

  describe 'DELETE destroy' do
    subject(:destroy!) { delete admin_application_settings_slack_path }

    context 'when user is not an admin' do
      before_all do
        sign_in(user)
      end

      it 'responds with status :not_found' do
        destroy!

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is an admin' do
      before do
        sign_in(admin)
      end

      it 'destroys the record and redirects back to #edit' do
        create(:gitlab_slack_application_integration, :instance,
          slack_integration: build(:slack_integration)
        )

        expect { destroy! }
          .to change { Integrations::GitlabSlackApplication.for_instance.first&.slack_integration }.to(nil)
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url)
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(gitlab_for_slack_app_instance_and_group_level: false)
        end

        it 'responds with status :not_found' do
          destroy!

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
