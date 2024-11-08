# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Package, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  describe 'relationships' do
    it { is_expected.to have_many(:installable_nuget_package_files).inverse_of(:package) }
    it { is_expected.to have_one(:nuget_metadatum).inverse_of(:package) }
    it { is_expected.to have_many(:nuget_symbols).inverse_of(:package) }
  end

  describe 'validations' do
    describe '#name' do
      it 'allows accepted values' do
        is_expected.to allow_values('My.Package', 'My.Package.Mvc', 'MyPackage', 'My.23.Package', 'My23Package',
          'runtime.my-test64.runtime.package.Mvc', 'my_package').for(:name)
      end

      it 'does not allow unaccepted values' do
        is_expected.not_to allow_values('My/package', '../../../my_package', '%2e%2e%2fmy_package').for(:name)
      end
    end

    describe '#version' do
      it 'allows accepted values' do
        is_expected.to allow_values('1.2', '1.2.3', '1.2.3.4', '1.2.3-beta', '1.2.3-alpha.3').for(:version)
      end

      it 'does not allow unaccepted values' do
        is_expected.not_to allow_values('1', '1./2.3', '../../../../../1.2.3', '%2e%2e%2f1.2.3').for(:version)
      end
    end
  end

  describe '.with_nuget_version_or_normalized_version' do
    let_it_be(:nuget_package) { create(:nuget_package, :with_metadatum, version: '1.0.7+r3456') }

    subject { described_class.with_nuget_version_or_normalized_version(version, with_normalized: with_normalized) }

    where(:version, :with_normalized, :expected) do
      '1.0.7'       | true  | [ref(:nuget_package)]
      '1.0.7'       | false | []
      '1.0.7+r3456' | true  | [ref(:nuget_package)]
      '1.0.7+r3456' | false | [ref(:nuget_package)]
    end

    with_them do
      it { is_expected.to match_array(expected) }
    end
  end

  describe '.without_nuget_temporary_name' do
    let!(:package1) { create(:nuget_package) }
    let!(:package2) { create(:nuget_package, name: Packages::Nuget::TEMPORARY_PACKAGE_NAME) }

    subject(:result) { described_class.without_nuget_temporary_name }

    it 'does not include nuget temporary packages' do
      expect(result).to eq([package1])
    end
  end

  describe '.including_dependency_links_with_nuget_metadatum' do
    let_it_be(:package) { create(:nuget_package) }
    let_it_be(:packages_dependency_link) { create(:packages_dependency_link, :with_nuget_metadatum, package: package) }

    subject(:result) { described_class.including_dependency_links_with_nuget_metadatum }

    it 'preloads associations', :aggregate_failures do
      package = result.first
      dependency_link = package.dependency_links.first

      expect(package.association(:dependency_links)).to be_loaded
      expect(dependency_link.association(:dependency)).to be_loaded
      expect(dependency_link.association(:nuget_metadatum)).to be_loaded
    end
  end

  describe '.preload_nuget_metadatum' do
    let_it_be(:package) { create(:nuget_package, :with_metadatum) }

    subject(:result) { described_class.preload_nuget_metadatum }

    it 'preloads nuget metadatum' do
      expect(result.first.association(:nuget_metadatum)).to be_loaded
    end
  end

  describe '.preload_nuget_files' do
    let_it_be(:package) { create(:nuget_package) }

    subject(:result) { described_class.preload_nuget_files }

    it 'preloads installable nuget files' do
      expect(result.first.association(:installable_nuget_package_files)).to be_loaded
    end
  end

  describe '#normalized_nuget_version' do
    let_it_be(:package) { create(:nuget_package, :with_metadatum, version: '1.0') }

    let(:normalized_version) { '1.0.0' }

    subject { package.normalized_nuget_version }

    it { is_expected.to eq(normalized_version) }
  end
end
