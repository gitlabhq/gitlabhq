# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillImportSourceUserPlaceholderReferencesExpiresAt,
  feature_category: :importers do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:import_source_users) { table(:import_source_users) }
  let(:import_source_user_placeholder_references) { table(:import_source_user_placeholder_references) }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:namespace) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:source_user) do
    import_source_users.create!(
      namespace_id: namespace.id,
      source_user_identifier: 'user-1',
      source_hostname: 'https://example.com',
      import_type: 'github'
    )
  end

  let(:created_at) { 3.years.ago }

  let!(:reference_without_expiry) do
    travel_to(created_at) do
      import_source_user_placeholder_references.create!(
        source_user_id: source_user.id,
        namespace_id: namespace.id,
        model: 'Issue',
        user_reference_column: 'author_id',
        alias_version: 1,
        numeric_key: 1
      )
    end
  end

  let!(:reference_with_expiry) do
    import_source_user_placeholder_references.create!(
      source_user_id: source_user.id,
      namespace_id: namespace.id,
      model: 'Issue',
      user_reference_column: 'author_id',
      alias_version: 1,
      numeric_key: 2,
      expires_at: 1.day.from_now
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_cursor: [reference_without_expiry.id],
      end_cursor: [reference_with_expiry.id],
      batch_table: :import_source_user_placeholder_references,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: connection
    ).perform
  end

  it 'backfills expires_at to one year from now, regardless of created_at' do
    original_expires_at = reference_with_expiry.reload.expires_at

    perform_migration

    # NOW() runs in Postgres, so compare against Ruby's clock with a tolerant window
    # rather than freeze_time, which can't affect the database server's own clock.
    expect(reference_without_expiry.reload.expires_at).to be_within(10.seconds).of(1.year.from_now)
    expect(reference_with_expiry.reload.expires_at).to be_within(1.second).of(original_expires_at)
  end
end
