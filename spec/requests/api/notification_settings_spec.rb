# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NotificationSettings, feature_category: :team_planning do
  let(:user) { create(:user) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project, :public, creator_id: user.id, namespace: group) }

  describe "GET /notification_settings" do
    it "returns global notification settings for the current user" do
      get api("/notification_settings", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['notification_email']).to eq(user.notification_email_or_default)
      expect(json_response['level']).to eq(user.global_notification_setting.level)
    end
  end

  describe "PUT /notification_settings" do
    let(:email) { create(:email, :confirmed, user: user) }

    it "updates global notification settings for the current user" do
      put api("/notification_settings", user), params: { level: 'watch', notification_email: email.email }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['notification_email']).to eq(email.email)
      expect(user.reload.notification_email).to eq(email.email)
      expect(json_response['level']).to eq(user.reload.global_notification_setting.level)
    end
  end

  describe "PUT /notification_settings" do
    it "fails on non-user email address" do
      put api("/notification_settings", user), params: { notification_email: 'invalid@example.com' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe "GET /groups/:id/notification_settings" do
    it "returns group level notification settings for the current user" do
      get api("/groups/#{group.id}/notification_settings", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['level']).to eq(user.notification_settings_for(group).level)
    end
  end

  describe "PUT /groups/:id/notification_settings" do
    it "updates group level notification settings for the current user" do
      put api("/groups/#{group.id}/notification_settings", user), params: { level: 'watch' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['level']).to eq(user.reload.notification_settings_for(group).level)
    end
  end

  describe "GET /projects/:id/notification_settings" do
    it "returns project level notification settings for the current user" do
      get api("/projects/#{project.id}/notification_settings", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['level']).to eq(user.notification_settings_for(project).level)
    end
  end

  describe "PUT /projects/:id/notification_settings" do
    it "updates project level notification settings for the current user" do
      put api("/projects/#{project.id}/notification_settings", user), params: { level: 'custom', new_note: true, moved_project: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['level']).to eq(user.reload.notification_settings_for(project).level)
      expect(json_response['events']['new_note']).to be_truthy
      expect(json_response['events']['new_issue']).to be_falsey
      expect(json_response['events']['moved_project']).to be_truthy
    end
  end

  describe "PUT /projects/:id/notification_settings" do
    it "fails on invalid level" do
      put api("/projects/#{project.id}/notification_settings", user), params: { level: 'invalid' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
