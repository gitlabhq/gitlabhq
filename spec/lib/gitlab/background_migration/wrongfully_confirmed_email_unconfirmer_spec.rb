# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::WrongfullyConfirmedEmailUnconfirmer, schema: 20200615111857 do
  let(:users) { table(:users) }
  let(:emails) { table(:emails) }
  let(:user_synced_attributes_metadata) { table(:user_synced_attributes_metadata) }
  let(:confirmed_at_2_days_ago) { 2.days.ago }
  let(:confirmed_at_3_days_ago) { 3.days.ago }
  let(:one_year_ago) { 1.year.ago }

  let!(:user_needs_migration_1) { users.create!(name: 'user1', email: 'test1@test.com', state: 'active', projects_limit: 1, confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:user_needs_migration_2) { users.create!(name: 'user2', email: 'test2@test.com', unconfirmed_email: 'unconfirmed@test.com', state: 'active', projects_limit: 1, confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:user_does_not_need_migration) { users.create!(name: 'user3', email: 'test3@test.com', state: 'active', projects_limit: 1) }
  let!(:inactive_user) { users.create!(name: 'user4', email: 'test4@test.com', state: 'blocked', projects_limit: 1, confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:alert_bot_user) { users.create!(name: 'user5', email: 'test5@test.com', state: 'active', user_type: 2, projects_limit: 1, confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:user_has_synced_email) { users.create!(name: 'user6', email: 'test6@test.com', state: 'active', projects_limit: 1, confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:synced_attributes_metadata_for_user) { user_synced_attributes_metadata.create!(user_id: user_has_synced_email.id, email_synced: true) }

  let!(:bad_email_1) { emails.create!(user_id: user_needs_migration_1.id, email: 'other1@test.com', confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:bad_email_2) { emails.create!(user_id: user_needs_migration_2.id, email: 'other2@test.com', confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:bad_email_3_inactive_user) { emails.create!(user_id: inactive_user.id, email: 'other-inactive@test.com', confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:bad_email_4_bot_user) { emails.create!(user_id: alert_bot_user.id, email: 'other-bot@test.com', confirmed_at: confirmed_at_3_days_ago, confirmation_sent_at: one_year_ago) }

  let!(:good_email_1) { emails.create!(user_id: user_needs_migration_2.id, email: 'other3@test.com', confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }
  let!(:good_email_2) { emails.create!(user_id: user_needs_migration_2.id, email: 'other4@test.com', confirmed_at: nil) }
  let!(:good_email_3) { emails.create!(user_id: user_does_not_need_migration.id, email: 'other5@test.com', confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }

  let!(:second_email_for_user_with_synced_email) { emails.create!(user_id: user_has_synced_email.id, email: 'other6@test.com', confirmed_at: confirmed_at_2_days_ago, confirmation_sent_at: one_year_ago) }

  subject do
    email_ids = [bad_email_1, bad_email_2, good_email_1, good_email_2, good_email_3, second_email_for_user_with_synced_email].map(&:id)

    described_class.new.perform(email_ids.min, email_ids.max)
  end

  it 'does not change irrelevant email records' do
    subject

    expect(good_email_1.reload.confirmed_at).to be_within(1.second).of(confirmed_at_2_days_ago)
    expect(good_email_2.reload.confirmed_at).to be_nil
    expect(good_email_3.reload.confirmed_at).to be_within(1.second).of(confirmed_at_2_days_ago)

    expect(bad_email_3_inactive_user.reload.confirmed_at).to be_within(1.second).of(confirmed_at_3_days_ago)
    expect(bad_email_4_bot_user.reload.confirmed_at).to be_within(1.second).of(confirmed_at_3_days_ago)

    expect(good_email_1.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
    expect(good_email_2.reload.confirmation_sent_at).to be_nil
    expect(good_email_3.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)

    expect(bad_email_3_inactive_user.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
    expect(bad_email_4_bot_user.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
  end

  it 'clears the `unconfirmed_email` field' do
    subject

    user_needs_migration_2.reload
    expect(user_needs_migration_2.unconfirmed_email).to be_nil
  end

  it 'does not change irrelevant user records' do
    subject

    expect(user_does_not_need_migration.reload.confirmed_at).to be_nil
    expect(inactive_user.reload.confirmed_at).to be_within(1.second).of(confirmed_at_3_days_ago)
    expect(alert_bot_user.reload.confirmed_at).to be_within(1.second).of(confirmed_at_3_days_ago)
    expect(user_has_synced_email.reload.confirmed_at).to be_within(1.second).of(confirmed_at_2_days_ago)

    expect(user_does_not_need_migration.reload.confirmation_sent_at).to be_nil
    expect(inactive_user.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
    expect(alert_bot_user.reload.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
    expect(user_has_synced_email.confirmation_sent_at).to be_within(1.second).of(one_year_ago)
  end

  it 'updates confirmation_sent_at column' do
    subject

    expect(user_needs_migration_1.reload.confirmation_sent_at).to be_within(1.minute).of(Time.now)
    expect(user_needs_migration_2.reload.confirmation_sent_at).to be_within(1.minute).of(Time.now)

    expect(bad_email_1.reload.confirmation_sent_at).to be_within(1.minute).of(Time.now)
    expect(bad_email_2.reload.confirmation_sent_at).to be_within(1.minute).of(Time.now)
  end

  it 'unconfirms bad email records' do
    subject

    expect(bad_email_1.reload.confirmed_at).to be_nil
    expect(bad_email_2.reload.confirmed_at).to be_nil

    expect(bad_email_1.reload.confirmation_token).not_to be_nil
    expect(bad_email_2.reload.confirmation_token).not_to be_nil
  end

  it 'unconfirms user records' do
    subject

    expect(user_needs_migration_1.reload.confirmed_at).to be_nil
    expect(user_needs_migration_2.reload.confirmed_at).to be_nil

    expect(user_needs_migration_1.reload.confirmation_token).not_to be_nil
    expect(user_needs_migration_2.reload.confirmation_token).not_to be_nil
  end

  context 'enqueued jobs' do
    let(:user_1) { User.find(user_needs_migration_1.id) }
    let(:user_2) { User.find(user_needs_migration_2.id) }

    let(:email_1) { Email.find(bad_email_1.id) }
    let(:email_2) { Email.find(bad_email_2.id) }

    it 'enqueues the email confirmation and the unconfirm notification mailer jobs' do
      allow(DeviseMailer).to receive(:confirmation_instructions).and_call_original
      allow(Gitlab::BackgroundMigration::Mailers::UnconfirmMailer).to receive(:unconfirm_notification_email).and_call_original

      subject

      expect(DeviseMailer).to have_received(:confirmation_instructions).with(email_1, email_1.confirmation_token)
      expect(DeviseMailer).to have_received(:confirmation_instructions).with(email_2, email_2.confirmation_token)

      expect(Gitlab::BackgroundMigration::Mailers::UnconfirmMailer).to have_received(:unconfirm_notification_email).with(user_1)
      expect(DeviseMailer).to have_received(:confirmation_instructions).with(user_1, user_1.confirmation_token)

      expect(Gitlab::BackgroundMigration::Mailers::UnconfirmMailer).to have_received(:unconfirm_notification_email).with(user_2)
      expect(DeviseMailer).to have_received(:confirmation_instructions).with(user_2, user_2.confirmation_token)
    end
  end
end
