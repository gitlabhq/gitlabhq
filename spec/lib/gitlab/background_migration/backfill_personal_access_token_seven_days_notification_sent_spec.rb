# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPersonalAccessTokenSevenDaysNotificationSent, feature_category: :system_access do
  let(:pats_table) { table(:personal_access_tokens) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'default org', path: 'dflt') }
  let!(:user) { users.create!(email: 'capybara@example.com', encrypted_password: 'abc123', projects_limit: 2) }
  let!(:pat_to_update) do
    pats_table.create!(name: 'notified token', expire_notification_delivered: true, expires_at: Date.current,
      user_id: user.id, organization_id: organization.id)
  end

  let!(:seven_days_notified) do
    pats_table.create!(name: 'seven days token', expire_notification_delivered: true, expires_at: Date.current,
      seven_days_notification_sent_at: Time.current - 1.day, user_id: user.id, organization_id: organization.id)
  end

  let!(:not_notified_pat) do
    pats_table.create!(name: 'not notified token', expires_at: Date.current + 1, user_id: user.id,
      organization_id: organization.id)
  end

  let!(:no_expiry_pat) do
    pats_table.create!(name: 'no expiry token', expire_notification_delivered: true, user_id: user.id,
      organization_id: organization.id)
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: pats_table.first.id,
        end_id: pats_table.last.id,
        batch_table: :personal_access_tokens,
        batch_column: :id,
        sub_batch_size: pats_table.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    it 'backfills seven_days_notification_sent_at field', :freeze_time do
      expect(pat_to_update.reload.seven_days_notification_sent_at).to be_nil
      expect(seven_days_notified.reload.seven_days_notification_sent_at).to eq(Time.current - 1.day)
      expect(not_notified_pat.reload.seven_days_notification_sent_at).to be_nil
      expect(no_expiry_pat.reload.seven_days_notification_sent_at).to be_nil

      perform_migration

      # db updates do not use the same timezone as Rails; default to UTC
      db_updated_time = Time.utc(Time.current.year, Time.current.month, Time.current.day) - 7.days
      expect(pat_to_update.reload.seven_days_notification_sent_at).to eq(db_updated_time)

      expect(seven_days_notified.reload.seven_days_notification_sent_at).to eq(Time.current - 1.day)
      expect(not_notified_pat.reload.seven_days_notification_sent_at).to be_nil
      expect(no_expiry_pat.reload.seven_days_notification_sent_at).to be_nil
    end
  end
end
