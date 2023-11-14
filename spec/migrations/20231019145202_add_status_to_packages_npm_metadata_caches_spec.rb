# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddStatusToPackagesNpmMetadataCaches, feature_category: :package_registry do
  let(:npm_metadata_caches) { table(:packages_npm_metadata_caches) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(npm_metadata_caches.column_names).not_to include('status')
      }

      migration.after -> {
        npm_metadata_caches.reset_column_information

        expect(npm_metadata_caches.column_names).to include('status')
      }
    end
  end
end
