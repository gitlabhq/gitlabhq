# frozen_string_literal: true

require 'spec_helper'

# The test setup must begin before
# 20200806004742_add_not_null_constraint_on_file_store_to_package_files.rb
# has run, or else we cannot insert a row with `NULL` `file_store` to
# test against.
RSpec.describe Gitlab::BackgroundMigration::SetNullPackageFilesFileStoreToLocalValue, schema: 20200806004232 do
  let!(:packages_package_files) { table(:packages_package_files) }
  let!(:packages_packages)      { table(:packages_packages) }
  let!(:projects)               { table(:projects) }
  let!(:namespaces)             { table(:namespaces) }
  let!(:namespace)              { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project)                { projects.create!(namespace_id: namespace.id) }
  let!(:package)                { packages_packages.create!(project_id: project.id, name: 'bar', package_type: 1) }

  it 'correctly migrates nil file_store to 1' do
    file_store_1 = packages_package_files.create!(file_store: 1, file_name: 'foo_1', file: 'foo_1', package_id: package.id)
    file_store_2 = packages_package_files.create!(file_store: 2, file_name: 'foo_2', file: 'foo_2', package_id: package.id)
    file_store_nil = packages_package_files.create!(file_store: nil, file_name: 'foo_nil', file: 'foo_nil', package_id: package.id)

    described_class.new.perform(file_store_1.id, file_store_nil.id)

    file_store_1.reload
    file_store_2.reload
    file_store_nil.reload

    expect(file_store_1.file_store).to eq(1)   # unchanged
    expect(file_store_2.file_store).to eq(2)   # unchanged
    expect(file_store_nil.file_store).to eq(1) # nil => 1
  end
end
