# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::PackagePresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:package_name) { "@#{project.root_namespace.path}/test" }

  let!(:package1) { create(:npm_package, version: '1.0.4', project: project, name: package_name) }
  let!(:package2) { create(:npm_package, version: '1.0.6', project: project, name: package_name) }
  let!(:latest_package) { create(:npm_package, version: '1.0.11', project: project, name: package_name) }
  let(:packages) { project.packages.npm.with_name(package_name).last_of_each_version }
  let(:presenter) { described_class.new(package_name, packages) }

  describe '#versions' do
    subject { presenter.versions }

    context 'for packages without dependencies' do
      it { is_expected.to be_a(Hash) }
      it { expect(subject[package1.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
      it { expect(subject[package2.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }

      described_class::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        it { expect(subject.dig(package1.version, dependency_type)).to be nil }
        it { expect(subject.dig(package2.version, dependency_type)).to be nil }
      end
    end

    context 'for packages with dependencies' do
      described_class::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        let!("package_dependency_link_for_#{dependency_type}") { create(:packages_dependency_link, package: package1, dependency_type: dependency_type) }
      end

      it { is_expected.to be_a(Hash) }
      it { expect(subject[package1.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
      it { expect(subject[package2.version].with_indifferent_access).to match_schema('public_api/v4/packages/npm_package_version') }
      described_class::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
        it { expect(subject.dig(package1.version, dependency_type.to_s)).to be_any }
      end
    end
  end

  describe '#dist_tags' do
    subject { presenter.dist_tags }

    context 'for packages without tags' do
      it { is_expected.to be_a(Hash) }
      it { expect(subject["latest"]).to eq(latest_package.version) }
    end

    context 'for packages with tags' do
      let!(:package_tag1) { create(:packages_tag, package: package1, name: 'release_a') }
      let!(:package_tag2) { create(:packages_tag, package: package1, name: 'test_release') }
      let!(:package_tag3) { create(:packages_tag, package: package2, name: 'release_b') }
      let!(:package_tag4) { create(:packages_tag, package: latest_package, name: 'release_c') }
      let!(:package_tag5) { create(:packages_tag, package: latest_package, name: 'latest') }

      it { is_expected.to be_a(Hash) }
      it { expect(subject[package_tag1.name]).to eq(package1.version) }
      it { expect(subject[package_tag2.name]).to eq(package1.version) }
      it { expect(subject[package_tag3.name]).to eq(package2.version) }
      it { expect(subject[package_tag4.name]).to eq(latest_package.version) }
      it { expect(subject[package_tag5.name]).to eq(latest_package.version) }
    end
  end
end
