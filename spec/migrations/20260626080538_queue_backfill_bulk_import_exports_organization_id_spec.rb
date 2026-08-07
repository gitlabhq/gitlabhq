# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillBulkImportExportsOrganizationId, migration: :gitlab_main_org, feature_category: :importers do
  it 'does nothing' do
    reversible_migration do |migration|
      migration.before -> {
        expect('BackfillBulkImportExportsOrganizationId').not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect('BackfillBulkImportExportsOrganizationId').not_to have_scheduled_batched_migration
      }
    end
  end
end
