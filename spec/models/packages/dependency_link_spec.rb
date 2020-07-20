# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::DependencyLink, type: :model do
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
end
