# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Gitlab::BackgroundMigration::BackfillPlaceholderUsersDetailsFromSourceUsers, feature_category: :importers do
  let(:migration_attrs) do
    {
      start_id: import_source_users_table.minimum(:id),
      end_id: import_source_users_table.maximum(:id),
      batch_table: :import_source_users,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    }
  end

  let(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { ApplicationRecord.connection }

  let(:import_source_users_table) { table(:import_source_users) }
  let(:import_placeholder_user_details_table) { table(:import_placeholder_user_details) }
  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:organizations_table) { table(:organizations) }

  let(:organization) { create_organization }
  let(:namespace) { create_namespace(organization_id: organization.id) }
  let(:user) { create_user(email: "test1@example.com", username: "test1") }

  let(:source_user_without_placeholder) { create_source_user(placeholder_user_id: nil, namespace_id: namespace.id) }
  let(:existing_user) { create_user(email: "test2@example.com", username: "test2") }
  let(:source_user_with_existing_detail) do
    create_source_user(placeholder_user_id: existing_user.id, namespace_id: namespace.id)
  end

  let!(:existing_detail) do
    create_placeholder_user_detail(placeholder_user_id: existing_user.id, namespace_id: namespace.id,
      organization_id: organization.id)
  end

  describe '#perform' do
    it 'creates placeholder user details for source users without them', :aggregate_failures do
      create_source_user(placeholder_user_id: user.id, namespace_id: namespace.id)

      expect do
        migration.perform
      end.to change { count_placeholder_user_details }.by(1)

      detail = find_placeholder_user_detail(user.id)
      expect(detail).to be_present
      expect(detail['namespace_id']).to eq(namespace.id)
      expect(detail['organization_id']).to eq(organization.id)
    end

    it 'skips source users without placeholder_user_id' do
      create_source_user(placeholder_user_id: nil, namespace_id: namespace.id)

      expect do
        migration.perform
      end.not_to change { count_placeholder_user_details }
    end

    it 'skips source users that already have placeholder user details' do
      create_source_user(placeholder_user_id: existing_user.id, namespace_id: namespace.id)

      expect do
        migration.perform
      end.not_to change { count_placeholder_user_details(existing_user.id) }
    end

    it 'logs error and re-raises exception when bulk insert fails', :aggregate_failures do
      create_source_user(placeholder_user_id: user.id, namespace_id: namespace.id)

      logger = instance_double(Gitlab::BackgroundMigration::Logger)
      allow(Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(logger)

      exception = StandardError.new("Database connection error")
      allow(Gitlab::BackgroundMigration::BackfillPlaceholderUsersDetailsFromSourceUsers::ImportPlaceholderUserDetail)
        .to receive(:upsert_all).and_raise(exception)

      expect(logger).to receive(:error).with(
        hash_including(
          message: "Error bulk creating placeholder user details: Database connection error",
          count: 1,
          placeholder_user_ids: [user.id]
        )
      )
      expect { migration.perform }.to raise_error(StandardError, "Database connection error")
    end

    it 'processes multiple batches correctly', :aggregate_failures do
      user3 = create_user(email: "test3@example.com", username: "test3")
      user4 = create_user(email: "test4@example.com", username: "test4")
      user5 = create_user(email: "test5@example.com", username: "test5")

      create_source_user(placeholder_user_id: user.id, namespace_id: namespace.id)
      create_source_user(placeholder_user_id: user3.id, namespace_id: namespace.id)
      create_source_user(placeholder_user_id: user4.id, namespace_id: namespace.id)
      create_source_user(placeholder_user_id: user5.id, namespace_id: namespace.id)

      create_placeholder_user_detail(placeholder_user_id: user4.id, namespace_id: namespace.id,
        organization_id: organization.id)
      create_source_user(placeholder_user_id: nil, namespace_id: namespace.id)

      expect do
        migration.perform
      end.to change { count_placeholder_user_details }.by(3)
    end
  end

  def create_organization
    organizations_table.create!(
      name: 'GitLab Enterprise',
      path: 'gitlab-enterprise'
    )
  end

  def create_namespace(organization_id:)
    namespaces_table.create!(
      name: 'Engineering Department',
      path: 'engineering-dept',
      organization_id: organization_id
    )
  end

  def create_user(overrides = {})
    attrs = {
      email: "test@example.com",
      notification_email: "test@example.com",
      name: "test",
      username: "test",
      state: "active",
      projects_limit: 10,
      organization_id: organization.id
    }.merge(overrides)

    users_table.create!(attrs)
  end

  def create_source_user(placeholder_user_id:, namespace_id:)
    import_source_users_table.create!(
      placeholder_user_id: placeholder_user_id,
      namespace_id: namespace_id,
      source_user_identifier: SecureRandom.uuid,
      source_hostname: 'https://gitlab.com',
      source_name: 'test-user',
      source_username: 'test-user1',
      import_type: 'gitlab_migration'
    )
  end

  def create_placeholder_user_detail(placeholder_user_id:, namespace_id:, organization_id:)
    import_placeholder_user_details_table.create!(
      placeholder_user_id: placeholder_user_id,
      namespace_id: namespace_id,
      organization_id: organization_id
    )
  end

  def count_placeholder_user_details(placeholder_user_id = nil)
    query = import_placeholder_user_details_table
    query = query.where(placeholder_user_id: placeholder_user_id) if placeholder_user_id
    query.count
  end

  def find_placeholder_user_detail(placeholder_user_id)
    Import::PlaceholderUserDetail.find_by(placeholder_user_id: placeholder_user_id)
  end
end
