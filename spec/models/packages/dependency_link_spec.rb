# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::DependencyLink, type: :model, feature_category: :package_registry do
  let_it_be(:package1) { create(:npm_package, package_files: []) }
  let_it_be(:package2) { create(:npm_package, package_files: []) }
  let_it_be(:dependency1) { create(:packages_dependency) }
  let_it_be(:dependency2) { create(:packages_dependency) }

  let_it_be(:dependency_link1) do
    create(:packages_dependency_link, :dev_dependencies, package: package1, dependency: dependency1)
  end

  let_it_be(:dependency_link2) do
    create(:packages_dependency_link, :dependencies, package: package1, dependency: dependency2)
  end

  let_it_be(:dependency_link3) do
    create(:packages_dependency_link, :dependencies, package: package2, dependency: dependency1)
  end

  let_it_be(:dependency_link4) do
    create(:packages_dependency_link, :dependencies, package: package2, dependency: dependency2)
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:dependency_links) }
    it { is_expected.to belong_to(:dependency).inverse_of(:dependency_links) }
    it { is_expected.to have_one(:nuget_metadatum).inverse_of(:dependency_link) }
  end

  describe 'validations' do
    subject { create(:packages_dependency_link) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:dependency) }

    context 'package_id and package_dependency_id uniqueness for dependency_type' do
      it 'is not valid' do
        exisiting_link = subject
        link = build(
          :packages_dependency_link,
          package: exisiting_link.package,
          dependency: exisiting_link.dependency,
          dependency_type: exisiting_link.dependency_type
        )

        expect(link).not_to be_valid
        expect(link.errors.to_a).to include("Dependency type has already been taken")
      end
    end
  end

  context 'with multiple links' do
    let_it_be(:link1) { create(:packages_dependency_link) }
    let_it_be(:link2) { create(:packages_dependency_link, dependency: link1.dependency, dependency_type: :devDependencies) }
    let_it_be(:link3) { create(:packages_dependency_link, dependency: link1.dependency, dependency_type: :bundleDependencies) }

    subject { described_class }

    describe '.with_dependency_type' do
      it 'returns links of the given type' do
        expect(subject.with_dependency_type(:bundleDependencies)).to eq([link3])
      end
    end

    describe '.for_package' do
      let_it_be(:link1) { create(:packages_dependency_link) }
      let_it_be(:link2) { create(:packages_dependency_link, dependency: link1.dependency, dependency_type: :devDependencies) }
      let_it_be(:link3) { create(:packages_dependency_link, dependency: link1.dependency, dependency_type: :bundleDependencies) }

      it 'returns the link for the given package' do
        expect(subject.for_package(link1.package)).to eq([link1])
      end
    end
  end

  describe '.dependency_ids_grouped_by_type' do
    let(:packages) { Packages::Package.where(id: [package1.id, package2.id]) }

    subject { described_class.dependency_ids_grouped_by_type(packages) }

    it 'aggregates dependencies by type', :aggregate_failures do
      result = Gitlab::Json.parse(subject.to_json)

      expect(result.count).to eq(2)

      expect(result).to contain_exactly(
        hash_including(
          'package_id' => package1.id,
          'dependency_ids_by_type' => a_hash_including(
            '1' => contain_exactly(dependency2.id),
            '2' => contain_exactly(dependency1.id)
          )
        ),
        hash_including(
          'package_id' => package2.id,
          'dependency_ids_by_type' => a_hash_including(
            '1' => contain_exactly(dependency1.id, dependency2.id)
          )
        )
      )
    end
  end

  describe '.for_packages' do
    let(:packages) { Packages::Package.where(id: package1.id) }

    subject { described_class.for_packages(packages) }

    it 'returns dependency links for selected packages' do
      expect(subject).to contain_exactly(dependency_link1, dependency_link2)
    end
  end

  describe '.select_dependency_id' do
    subject { described_class.select_dependency_id }

    it 'returns only dependency_id' do
      expect(subject[0].attributes).to eq('dependency_id' => dependency1.id, 'id' => nil)
    end
  end
end
