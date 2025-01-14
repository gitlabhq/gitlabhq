# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateScimTokens, feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespaces) { table(:namespaces) }
  let(:scim_oauth_access_token) { table(:scim_oauth_access_tokens) }
  let(:group_scim_auth_access_token) { table(:group_scim_auth_access_tokens) }

  let(:migration_attrs) do
    {
      start_id: scim_oauth_access_token.minimum(:id),
      end_id: scim_oauth_access_token.maximum(:id),
      batch_table: :scim_oauth_access_tokens,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  let(:group1) { namespaces.create!(name: 'group1', path: 'group1', organization_id: organization.id) }
  let(:group2) { namespaces.create!(name: 'group2', path: 'group2', organization_id: organization.id) }

  let(:token1) do
    scim_oauth_access_token.create!(
      group_id: group1.id,
      token_encrypted: 'token_1',
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  let(:token2) do
    scim_oauth_access_token.create!(
      group_id: group2.id,
      token_encrypted: 'token_2',
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )
  end

  let(:token_without_group) do
    scim_oauth_access_token.create!(
      group_id: nil,
      token_encrypted: 'token_3',
      created_at: 3.days.ago,
      updated_at: 3.days.ago
    )
  end

  # Create all tokens before each test
  before do
    token1
    token2
    token_without_group
  end

  describe '#perform' do
    it 'migrates SCIM tokens with group_id to the new table' do
      expect { migration.perform }.to change { group_scim_auth_access_token.count }.by(2)

      migrated_tokens = group_scim_auth_access_token.all
      expect(migrated_tokens.map(&:group_id)).to match_array([group1.id, group2.id])
      expect(migrated_tokens.map(&:token_encrypted)).to match_array(%w[token_1 token_2])
    end

    it 'does not migrate tokens without group_id' do
      migration.perform

      expect(group_scim_auth_access_token.where(group_id: nil).count).to eq(0)
    end

    it 'handles duplicate migrations gracefully' do
      # First migration
      migration.perform
      initial_count = group_scim_auth_access_token.count

      # Second migration attempt
      migration.perform
      expect(group_scim_auth_access_token.count).to eq(initial_count)
    end

    it 'preserves timestamps during migration' do
      migration.perform

      original_token = scim_oauth_access_token.find(token1.id)
      migrated_token = group_scim_auth_access_token.find_by(temp_source_id: token1.id)

      expect(migrated_token.created_at).to be_within(1.second).of(original_token.created_at)
      expect(migrated_token.updated_at).to be_within(1.second).of(original_token.updated_at)
    end

    it 'sets temp_source_id to original id' do
      migration.perform

      migrated_token = group_scim_auth_access_token.find_by(temp_source_id: token1.id)
      expect(migrated_token).to be_present
      expect(migrated_token.temp_source_id).to eq(token1.id)
    end

    it 'processes tokens in batches' do
      allow(migration).to receive(:each_sub_batch).and_yield(scim_oauth_access_token.where(id: [token1.id]))

      migration.perform

      expect(group_scim_auth_access_token.count).to eq(1)
      expect(group_scim_auth_access_token.first.temp_source_id).to eq(token1.id)
    end
  end
end
