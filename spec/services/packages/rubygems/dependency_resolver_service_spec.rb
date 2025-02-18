# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rubygems::DependencyResolverService, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:package) { create(:rubygems_package, project: project) }
  let_it_be(:user) { create(:user) }

  let(:gem_name) { package.name }
  let(:service) { described_class.new(project, user, gem_name: gem_name) }

  describe '#execute' do
    subject { service.execute }

    context 'user without access' do
      it 'returns a service error' do
        expect(subject.error?).to be(true)
        expect(subject.message).to eq('forbidden')
      end
    end

    context 'user with access' do
      before do
        project.add_developer(user)
      end

      context 'when no package is found' do
        let(:gem_name) { nil }

        it 'returns a service error', :aggregate_failures do
          expect(subject.error?).to be(true)
          expect(subject.message).to eq("#{gem_name} not found")
        end
      end

      context 'package without dependencies' do
        it 'returns an empty dependencies array' do
          expected_result = [{
            name: package.name,
            number: package.version,
            platform: described_class::DEFAULT_PLATFORM,
            dependencies: []
          }]

          expect(subject.payload).to eq(expected_result)
        end
      end

      context 'package with dependencies' do
        let(:dependency_link) { create(:packages_dependency_link, :rubygems, package: package) }
        let(:dependency_link2) { create(:packages_dependency_link, :rubygems, package: package) }
        let(:dependency_link3) { create(:packages_dependency_link, :rubygems, package: package) }

        it 'returns a set of dependencies' do
          expected_result = [{
            name: package.name,
            number: package.version,
            platform: described_class::DEFAULT_PLATFORM,
            dependencies: [
              [dependency_link.dependency.name, dependency_link.dependency.version_pattern],
              [dependency_link2.dependency.name, dependency_link2.dependency.version_pattern],
              [dependency_link3.dependency.name, dependency_link3.dependency.version_pattern]
            ]
          }]

          expect(subject.payload).to eq(expected_result)
        end
      end

      context 'package with multiple versions' do
        let(:dependency_link) { create(:packages_dependency_link, :rubygems, package: package) }
        let(:dependency_link2) { create(:packages_dependency_link, :rubygems, package: package) }
        let(:dependency_link3) { create(:packages_dependency_link, :rubygems, package: package) }
        let(:package2) { create(:rubygems_package, project: project, name: package.name, version: '9.9.9') }
        let(:dependency_link4) { create(:packages_dependency_link, :rubygems, package: package2) }

        it 'returns a set of dependencies' do
          expected_result = [{
            name: package.name,
            number: package.version,
            platform: described_class::DEFAULT_PLATFORM,
            dependencies: [
              [dependency_link.dependency.name, dependency_link.dependency.version_pattern],
              [dependency_link2.dependency.name, dependency_link2.dependency.version_pattern],
              [dependency_link3.dependency.name, dependency_link3.dependency.version_pattern]
            ]
          }, {
            name: package2.name,
            number: package2.version,
            platform: described_class::DEFAULT_PLATFORM,
            dependencies: [
              [dependency_link4.dependency.name, dependency_link4.dependency.version_pattern]
            ]
          }]

          expect(subject.payload).to match_array(expected_result)
        end
      end
    end
  end
end
