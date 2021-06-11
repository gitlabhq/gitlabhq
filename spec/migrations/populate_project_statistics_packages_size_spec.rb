# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateProjectStatisticsPackagesSize do
  let(:project_statistics) { table(:project_statistics) }
  let(:namespaces)         { table(:namespaces) }
  let(:projects)           { table(:projects) }
  let(:packages)           { table(:packages_packages) }
  let(:package_files)      { table(:packages_package_files) }

  let(:file_size)      { 1.kilobyte }
  let(:repo_size)      { 2.megabytes }
  let(:lfs_size)       { 3.gigabytes }
  let(:artifacts_size) { 4.terabytes }
  let(:storage_size)   { repo_size + lfs_size + artifacts_size }

  let(:namespace)  { namespaces.create!(name: 'foo', path: 'foo') }
  let(:package)    { packages.create!(project_id: project.id, name: 'a package', package_type: 1) }
  let(:project)    { projects.create!(namespace_id: namespace.id) }

  let!(:statistics) { project_statistics.create!(project_id: project.id, namespace_id: namespace.id, storage_size: storage_size, repository_size: repo_size, lfs_objects_size: lfs_size, build_artifacts_size: artifacts_size) }
  let!(:package_file) { package_files.create!(package_id: package.id, file: 'a file.txt', file_name: 'a file.txt', size: file_size)}

  it 'backfills ProjectStatistics packages_size' do
    expect { migrate! }
      .to change { statistics.reload.packages_size }
      .from(nil).to(file_size)
  end

  it 'updates ProjectStatistics storage_size' do
    expect { migrate! }
      .to change { statistics.reload.storage_size }
      .by(file_size)
  end
end
