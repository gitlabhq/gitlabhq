# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIndexPackagesNpmMetadataCachesOnIdAndProjectIdAndStatus, feature_category: :package_registry do
  let(:index_name) { described_class::INDEX_NAME }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes(:packages_npm_metadata_caches).map(&:name))
          .not_to include(index_name)
      }

      migration.after -> {
        # npm_metadata_caches.reset_column_information

        expect(ActiveRecord::Base.connection.indexes(:packages_npm_metadata_caches).map(&:name))
          .to include(index_name)
      }
    end
  end
end
