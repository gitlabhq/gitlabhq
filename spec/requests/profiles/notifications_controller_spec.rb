# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view user notifications' do
  let(:user) do
    create(:user) do |user|
      user.emails.create(email: 'original@example.com', confirmed_at: Time.current)
      user.emails.create(email: 'new@example.com', confirmed_at: Time.current)
      user.notification_email = 'original@example.com'
      user.save!
    end
  end

  before do
    login_as(user)

    create_list(:group, 2) do |group|
      group.add_developer(user)
    end
  end

  def get_profile_notifications
    get profile_notifications_path
  end

  describe 'GET /profile/notifications' do
    # To be fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40457
    it 'has an N+1 due to an additional groups (with no parent group) - but should not' do
      get_profile_notifications

      control = ActiveRecord::QueryRecorder.new do
        get_profile_notifications
      end

      create_list(:group, 2) { |group| group.add_developer(user) }

      expect do
        get_profile_notifications
      end.to exceed_query_limit(control)
    end
  end
end
