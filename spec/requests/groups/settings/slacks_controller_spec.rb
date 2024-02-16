# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::SlacksController, feature_category: :integrations do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    stub_application_setting(slack_app_enabled: true)
  end

  def redirect_url(group)
    edit_group_settings_integration_path(
      group,
      Integrations::GitlabSlackApplication.to_param
    )
  end

  describe 'DELETE destroy' do
    subject(:destroy!) { delete group_settings_slack_path(group) }

    context 'when user is not an admin' do
      before_all do
        group.add_developer(user)
      end

      it 'responds with status :not_found' do
        destroy!

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is an admin' do
      before_all do
        group.add_owner(user)
      end

      it 'destroys the record and redirects back to #edit' do
        create(:gitlab_slack_application_integration, :group, group: group,
          slack_integration: build(:slack_integration)
        )

        expect { destroy! }
          .to change { Integrations::GitlabSlackApplication.for_group(group).first&.slack_integration }.to(nil)
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(group))
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
