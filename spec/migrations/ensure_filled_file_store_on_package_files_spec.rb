# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureFilledFileStoreOnPackageFiles, schema: 20200910175553 do
  let!(:packages_package_files) { table(:packages_package_files) }
  let!(:packages_packages) { table(:packages_packages) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:package) { packages_packages.create!(project_id: project.id, name: 'bar', package_type: 1) }

  before do
    constraint_name = 'check_4c5e6bb0b3'

    # In order to insert a row with a NULL to fill.
    ActiveRecord::Base.connection.execute "ALTER TABLE packages_package_files DROP CONSTRAINT #{constraint_name}"

    @file_store_1 = packages_package_files.create!(file_store: 1, file_name: 'foo_1', file: 'foo_1', package_id: package.id)
    @file_store_2 = packages_package_files.create!(file_store: 2, file_name: 'foo_2', file: 'foo_2', package_id: package.id)
    @file_store_nil = packages_package_files.create!(file_store: nil, file_name: 'foo_nil', file: 'foo_nil', package_id: package.id)

    # revert DB structure
    ActiveRecord::Base.connection.execute "ALTER TABLE packages_package_files ADD CONSTRAINT #{constraint_name} CHECK ((file_store IS NOT NULL)) NOT VALID"
  end

  it 'correctly migrates nil file_store to 1' do
    migrate!

    @file_store_1.reload
    @file_store_2.reload
    @file_store_nil.reload

    expect(@file_store_1.file_store).to eq(1)   # unchanged
    expect(@file_store_2.file_store).to eq(2)   # unchanged
    expect(@file_store_nil.file_store).to eq(1) # nil => 1
  end
end
