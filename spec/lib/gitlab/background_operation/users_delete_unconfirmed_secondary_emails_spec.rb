# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::UsersDeleteUnconfirmedSecondaryEmails, :background_operation, feature_category: :user_management do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:user) do
    table(:users).create!(
      username: 'testuser',
      email: 'testuser@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:cut_off_datetime) do
    ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
  end

  let!(:email_to_delete) { create_email('old-unconfirmed@example.com', nil, cut_off_datetime - 1.day) }
  let!(:email_to_delete_2) { create_email('another-old-unconfirmed@example.com', nil, cut_off_datetime - 2.days) }
  let!(:unconfirmed_email_to_keep) { create_email('recent-unconfirmed@example.com', nil, cut_off_datetime + 1.day) }
  let!(:confirmed_email) { create_email('confirmed@example.com', 1.day.ago, cut_off_datetime - 1.day) }
  let!(:email_at_cutoff) { create_email('cutoff@example.com', nil, cut_off_datetime + 1.second) }

  let!(:min_cursor) { table(:emails).minimum(:id) }
  let!(:max_cursor) { table(:emails).maximum(:id) }

  let!(:operation) do
    described_class.new(
      min_cursor: [min_cursor],
      max_cursor: [max_cursor],
      batch_table: :emails,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'deletes unconfirmed emails created before the cutoff date', :aggregate_failures do
    expect { operation.perform }
      .to change { table(:emails).exists?(email_to_delete.id) }.from(true).to(false)
      .and change { table(:emails).exists?(email_to_delete_2.id) }.from(true).to(false)
      .and not_change { table(:emails).exists?(unconfirmed_email_to_keep.id) }
      .and not_change { table(:emails).exists?(confirmed_email.id) }
      .and not_change { table(:emails).exists?(email_at_cutoff.id) }
  end

  it 'only deletes emails matching both conditions' do
    expect { operation.perform }.to change { table(:emails).count }.by(-2)
  end

  context 'with cells claims enabled' do
    before do
      allow(::Email).to receive(:cells_claims_enabled_for_attribute?).with(:email).and_return(true)
    end

    it 'schedules bulk claims destroy for deleted records' do
      expect(::Cells::BulkClaimsWorker).to receive(:perform_async).with(
        'Email', 'email', hash_including('destroy_metadata')
      ).at_least(:once)

      operation.perform
    end
  end

  context 'with cells claims disabled' do
    before do
      allow(::Email).to receive(:cells_claims_enabled_for_attribute?).with(:email).and_return(false)
    end

    it 'does not schedule bulk claims destroy' do
      expect(::Cells::BulkClaimsWorker).not_to receive(:perform_async)

      operation.perform
    end
  end

  context 'when no matching records exist' do
    let!(:operation) do
      described_class.new(
        min_cursor: [max_cursor + 1],
        max_cursor: [max_cursor + 100],
        batch_table: :emails,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ::ApplicationRecord.connection
      )
    end

    it 'does not delete anything' do
      expect { operation.perform }.not_to change { table(:emails).count }
    end
  end

  private

  def create_email(email_address, confirmed_at, created_at)
    table(:emails).create!(
      user_id: user.id,
      email: email_address,
      confirmed_at: confirmed_at,
      created_at: created_at
    )
  end
end
