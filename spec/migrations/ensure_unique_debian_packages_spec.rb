# frozen_string_literal: true

require 'spec_helper'

require_migration!
require_migration! 'add_unique_packages_index_when_debian'
require_migration! 'add_tmp_unique_packages_index_when_debian'

RSpec.describe EnsureUniqueDebianPackages, feature_category: :package_registry do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:packages) { table(:packages_packages) }

  let!(:group) { namespaces.create!(name: 'group', path: 'group_path') }
  let!(:project_namespace1) { namespaces.create!(name: 'name1', path: 'path1') }
  let!(:project_namespace2) { namespaces.create!(name: 'name2', path: 'path2') }

  let!(:project1) { projects.create!(namespace_id: group.id, project_namespace_id: project_namespace1.id) }
  let!(:project2) { projects.create!(namespace_id: group.id, project_namespace_id: project_namespace2.id) }

  let!(:debian_package1_1) do
    packages.create!(project_id: project1.id, package_type: 9, name: FFaker::Lorem.word, version: 'v1.0')
  end

  let(:debian_package1_2) do
    packages.create!(project_id: project1.id, package_type: 9, name: debian_package1_1.name,
      version: debian_package1_1.version)
  end

  let!(:pypi_package1_3) do
    packages.create!(project_id: project1.id, package_type: 5, name: debian_package1_1.name,
      version: debian_package1_1.version)
  end

  let!(:debian_package2_1) do
    packages.create!(project_id: project2.id, package_type: 9, name: debian_package1_1.name,
      version: debian_package1_1.version)
  end

  before do
    # Remove unique indices
    AddUniquePackagesIndexWhenDebian.new.down
    AddTmpUniquePackagesIndexWhenDebian.new.down
    # Then create the duplicate packages
    debian_package1_2
  end

  it 'marks as pending destruction the duplicated packages', :aggregate_failures do
    expect { migrate! }
      .to change { packages.where(status: 0).count }.from(4).to(3)
      .and not_change { packages.where(status: 1).count }
      .and not_change { packages.where(status: 2).count }
      .and not_change { packages.where(status: 3).count }
      .and change { packages.where(status: 4).count }.from(0).to(1)
  end
end
