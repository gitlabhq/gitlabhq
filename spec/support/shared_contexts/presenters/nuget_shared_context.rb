# frozen_string_literal: true

RSpec.shared_context 'with expected presenters dependency groups' do
  def expected_dependency_groups(project_id, package_name, package_version)
    [
      {
        id: "http://localhost/api/v4/projects/#{project_id}/packages/nuget/metadata/#{package_name}/#{package_version}.json#dependencyGroup/.netstandard2.0",
        target_framework: '.NETStandard2.0',
        type: 'PackageDependencyGroup',
        dependencies: [
          {
            id: "http://localhost/api/v4/projects/#{project_id}/packages/nuget/metadata/#{package_name}/#{package_version}.json#dependencyGroup/.netstandard2.0/newtonsoft.json",
            range: '12.0.3',
            name: 'Newtonsoft.Json',
            type: 'PackageDependency'
          }
        ]
      },
      {
        id: "http://localhost/api/v4/projects/#{project_id}/packages/nuget/metadata/#{package_name}/#{package_version}.json#dependencyGroup",
        type: 'PackageDependencyGroup',
        dependencies: [
          {
            id: "http://localhost/api/v4/projects/#{project_id}/packages/nuget/metadata/#{package_name}/#{package_version}.json#dependencyGroup/castle.core",
            range: '4.4.1',
            name: 'Castle.Core',
            type: 'PackageDependency'
          }
        ]
      }
    ]
  end

  def create_dependencies_for(package)
    dependency1 = Packages::Dependency.find_by(name: 'Newtonsoft.Json', version_pattern: '12.0.3') ||
      create(:packages_dependency, name: 'Newtonsoft.Json', version_pattern: '12.0.3')
    dependency2 = Packages::Dependency.find_by(name: 'Castle.Core', version_pattern: '4.4.1') ||
      create(:packages_dependency, name: 'Castle.Core', version_pattern: '4.4.1')

    create(:packages_dependency_link, :with_nuget_metadatum, package: package, dependency: dependency1)
    create(:packages_dependency_link, package: package, dependency: dependency2)
  end
end
