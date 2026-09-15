# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveOrganizationIdFromBulkImportExports, feature_category: :importers do
  let(:connection) { described_class.new.connection }

  it 'removes and restores the organization_id column' do
    reversible_migration do |migration|
      migration.before -> {
        expect(connection.column_exists?(:bulk_import_exports, :organization_id)).to be(true)
      }

      migration.after -> {
        expect(connection.column_exists?(:bulk_import_exports, :organization_id)).to be(false)
      }
    end
  end
end
