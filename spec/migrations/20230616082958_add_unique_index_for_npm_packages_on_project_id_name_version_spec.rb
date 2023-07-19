# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddUniqueIndexForNpmPackagesOnProjectIdNameVersion, feature_category: :package_registry do
  it 'schedules an index creation' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes('packages_packages').map(&:name))
          .not_to include('idx_packages_on_project_id_name_version_unique_when_npm')
      }

      migration.after -> {
        expect(ActiveRecord::Base.connection.indexes('packages_packages').map(&:name))
          .to include('idx_packages_on_project_id_name_version_unique_when_npm')
      }
    end
  end
end
