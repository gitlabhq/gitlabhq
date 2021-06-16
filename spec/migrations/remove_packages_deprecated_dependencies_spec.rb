# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemovePackagesDeprecatedDependencies do
  let(:projects) { table(:projects) }
  let(:packages) { table(:packages_packages) }
  let(:dependency_links) { table(:packages_dependency_links) }
  let(:dependencies) { table(:packages_dependencies) }

  before do
    projects.create!(id: 123, name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1)
    packages.create!(id: 1, name: 'package', version: '1.0.0', package_type: 4, project_id: 123)
    5.times do |i|
      dependencies.create!(id: i, name: "pkg_dependency_#{i}", version_pattern: '~1.0.0')
      dependency_links.create!(package_id: 1, dependency_id: i, dependency_type: 5)
    end
    dependencies.create!(id: 10, name: 'valid_pkg_dependency', version_pattern: '~2.5.0')
    dependency_links.create!(package_id: 1, dependency_id: 10, dependency_type: 1)
  end

  it 'removes all dependency links with type 5' do
    expect(dependency_links.count).to eq 6

    migrate!

    expect(dependency_links.count).to eq 1
  end
end
