# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillPackagesConanPackageReferences, feature_category: :database, migration_version: 20250204162346 do
  let(:finalized_status) { 6 }

  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      QueueBackfillPackagesConanPackageReferences.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillPackagesConanPackageReferences',
        table_name: 'packages_conan_file_metadata'
      ).first

      expect(migration.status).not_to eq(finalized_status)

      migrate!

      expect(migration.reload.status).to eq(finalized_status)

      QueueBackfillPackagesConanPackageReferences.new.down
    end
  end
end
