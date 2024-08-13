# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Nuget::CreateDependencyService, feature_category: :package_registry do
  let_it_be(:package, reload: true) { create(:nuget_package) }

  describe '#execute' do
    RSpec.shared_examples 'creating dependencies, links and nuget metadata for' do |expected_dependency_names, dependency_count, dependency_link_count|
      let(:dependencies_with_metadata) { dependencies.select { |dep| dep[:target_framework].present? } }

      it 'creates dependencies, links and nuget metadata' do
        expect { subject }
          .to change { Packages::Dependency.count }.by(dependency_count)
          .and change { Packages::DependencyLink.count }.by(dependency_link_count)
          .and change { Packages::Nuget::DependencyLinkMetadatum.count }.by(dependencies_with_metadata.size)
        expect(expected_dependency_names).to contain_exactly(*dependency_names)
        expect(package.dependency_links.map(&:dependency_type).uniq).to contain_exactly('dependencies')

        dependencies_with_metadata.each do |dependency|
          name = dependency[:name]
          version_pattern = service.send(:version_or_empty_string, dependency[:version])
          metadatum = package.dependency_links.joins(:dependency)
                                              .find_by(packages_dependencies: { name: name, version_pattern: version_pattern })
                                              .nuget_metadatum
          expect(metadatum.target_framework).to eq dependency[:target_framework]
        end
      end
    end

    let_it_be(:dependencies) do
      [
        { name: 'Moqi', version: '2.5.6' },
        { name: 'Castle.Core' },
        { name: 'Test.Dependency', version: '2.3.7', target_framework: '.NETStandard2.0' },
        { name: 'Newtonsoft.Json', version: '12.0.3', target_framework: '.NETStandard2.0' }
      ]
    end

    let(:dependency_names) { package.dependency_links.flat_map(&:dependency).map(&:name) }
    let(:service) { described_class.new(package, dependencies) }

    subject { service.execute }

    it_behaves_like 'creating dependencies, links and nuget metadata for', %w[Castle.Core Moqi Newtonsoft.Json Test.Dependency], 4, 4

    context 'with existing dependencies' do
      context 'in the same project' do
        let_it_be(:exisiting_dependency) { create(:packages_dependency, name: 'Moqi', version_pattern: '2.5.6', project: package.project) }

        it_behaves_like 'creating dependencies, links and nuget metadata for', %w[Castle.Core Moqi Newtonsoft.Json Test.Dependency], 3, 4
      end

      context 'in the different project' do
        let_it_be(:exisiting_dependency) { create(:packages_dependency, name: 'Moqi', version_pattern: '2.5.6') }

        it_behaves_like 'creating dependencies, links and nuget metadata for', %w[Castle.Core Moqi Newtonsoft.Json Test.Dependency], 4, 4
      end
    end

    context 'with dependencies with no target framework' do
      let_it_be(:dependencies) do
        [
          { name: 'Moqi', version: '2.5.6' },
          { name: 'Castle.Core' },
          { name: 'Test.Dependency', version: '2.3.7' },
          { name: 'Newtonsoft.Json', version: '12.0.3' }
        ]
      end

      it_behaves_like 'creating dependencies, links and nuget metadata for', %w[Castle.Core Moqi Newtonsoft.Json Test.Dependency], 4, 4
    end

    context 'with empty dependencies' do
      let_it_be(:dependencies) { [] }

      it 'is a no op' do
        expect(service).not_to receive(:create_dependency_links)
        expect(service).not_to receive(:create_dependency_link_metadata)

        subject
      end
    end
  end
end
