# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillNugetTemporaryPackagesToProcessingStatus, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:packages) { table(:packages_packages) }

  before do
    namespace = namespaces.create!(id: 123, name: 'test_namespace', path: 'test_namespace')
    project = projects.create!(id: 111, name: 'sample_project', path: 'sample_project', namespace_id: namespace.id)

    packages.create!(name: 'NuGet.Temporary.Package', version: '0.1.1', package_type: 4, status: 0, project_id: project.id)
    packages.create!(name: 'foo', version: '0.1.1', package_type: 4, status: 0, project_id: project.id)
    packages.create!(name: 'NuGet.Temporary.Package', version: '0.1.1', package_type: 4, status: 2, project_id: project.id)
    packages.create!(name: 'NuGet.Temporary.Package', version: '0.1.1', package_type: 1, status: 2, project_id: project.id)
    packages.create!(name: 'NuGet.Temporary.Package', version: '0.1.1', package_type: 1, status: 0, project_id: project.id)
  end

  it 'updates the applicable packages to processing status', :aggregate_failures do
    expect(packages.where(status: 0).count).to eq(3)
    expect(packages.where(status: 2).count).to eq(2)
    expect(packages.where(name: 'NuGet.Temporary.Package', package_type: 4, status: 0).count).to eq(1)

    migrate!

    expect(packages.where(status: 0).count).to eq(2)
    expect(packages.where(status: 2).count).to eq(3)
    expect(packages.where(name: 'NuGet.Temporary.Package', package_type: 4, status: 0).count).to eq(0)
  end
end
