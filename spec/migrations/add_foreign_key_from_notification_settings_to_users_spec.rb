# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180710162338_add_foreign_key_from_notification_settings_to_users.rb')

describe AddForeignKeyFromNotificationSettingsToUsers, :migration do
  let(:notification_settings) { table(:notification_settings) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }

  before do
    users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0)
    projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1)
  end

  describe 'removal of orphans without user' do
    let!(:notification_setting_without_user) { create_notification_settings!(user_id: 123) }
    let!(:notification_setting_with_user) { create_notification_settings!(user_id: users.last.id) }

    it 'removes orphaned notification_settings without user' do
      expect { migrate! }.to change { notification_settings.count }.by(-1)
    end

    it "doesn't remove notification_settings with valid user" do
      expect { migrate! }.not_to change { notification_setting_with_user.reload }
    end
  end

  def create_notification_settings!(**opts)
    notification_settings.create!(
      source_id: projects.last.id,
      source_type: 'Project',
      user_id: users.last.id,
      **opts)
  end
end
