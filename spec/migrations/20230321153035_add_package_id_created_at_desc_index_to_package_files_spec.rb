# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddPackageIdCreatedAtDescIndexToPackageFiles, feature_category: :package_registry do
  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes('packages_package_files').map(&:name))
          .not_to include('index_packages_package_files_on_package_id_and_created_at_desc')
      }

      migration.after -> {
        expect(ActiveRecord::Base.connection.indexes('packages_package_files').map(&:name))
          .to include('index_packages_package_files_on_package_id_and_created_at_desc')
      }
    end
  end
end
