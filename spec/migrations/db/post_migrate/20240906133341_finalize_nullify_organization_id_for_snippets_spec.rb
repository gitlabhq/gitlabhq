# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeNullifyOrganizationIdForSnippets, feature_category: :source_code_management, migration_version: 20240906133341 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      QueueNullifyOrganizationIdForSnippets.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'NullifyOrganizationIdForSnippets',
        table_name: 'snippets'
      ).first

      expect(migration.status).not_to eq(6)

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueNullifyOrganizationIdForSnippets.new.down
    end
  end
end
