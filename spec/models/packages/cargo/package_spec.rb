# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::Package, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to have_one(:cargo_metadatum).inverse_of(:package) }
  end

  describe 'validations' do
    describe '#name' do
      subject { build_stubbed(:cargo_package) }

      it 'allows accepted values' do
        is_expected.to allow_values('cargo-package', 'cargo-package123', 'cargo-package_123',
          'cargo-package-123').for(:name)
      end

      it 'does not allow special characters' do
        is_expected.not_to allow_values('cargo-package!', 'cargo-package@', 'cargo-package#',
          'cargo-package%').for(:name)
      end

      it 'does not allow names to start with non-alphabetic character' do
        is_expected.not_to allow_values('1cargo-package', '_cargo-package').for(:name)
      end

      it 'does not allow names with more than 64 characters' do
        is_expected.not_to allow_value('a' * 65).for(:name)
      end

      it 'does not allow reserved names' do
        is_expected.not_to allow_values('nul', 'con', 'prn', 'aux', 'com1', 'com2', 'com3', 'com4').for(:name)
      end
    end

    describe '.with_normalized_cargo_name' do
      let_it_be(:cargo_package) { create(:cargo_package, name: 'Foo-bAr_BAZ_buz') }
      let_it_be(:cargo_metadatum) { create(:cargo_metadatum, package: cargo_package) }

      subject(:packages_with_normalized_name) { described_class.with_normalized_cargo_name('foo-bar-baz-buz') }

      it { is_expected.to match_array([cargo_package]) }

      context 'when package has no metadatum' do
        let_it_be(:cargo_package_without_metadatum) { create(:cargo_package, name: 'Foo-bAr_BAZ_buz') }

        it 'does not include packages without metadatum' do
          expect(packages_with_normalized_name).not_to include(cargo_package_without_metadatum)
        end
      end
    end

    describe '.with_normalized_cargo_version' do
      let_it_be(:cargo_package) { create(:cargo_package, version: '1.0.0+build999') }
      let_it_be(:cargo_metadatum) { create(:cargo_metadatum, package: cargo_package) }

      subject(:packages_with_normalized_version) { described_class.with_normalized_cargo_version('1.0.0') }

      it { is_expected.to match_array([cargo_package]) }

      context 'when package has no metadatum' do
        let_it_be(:cargo_package_without_metadatum) { create(:cargo_package, version: '1.0.0+build999') }

        it 'does not include packages without metadatum' do
          expect(packages_with_normalized_version).not_to include(cargo_package_without_metadatum)
        end
      end
    end

    context 'for package uniqueness' do
      let_it_be(:existing_package) { create(:cargo_package, version: '1.0.0') }
      let_it_be(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      context 'when name and version are the same' do
        let(:new_package) do
          build(:cargo_package, project: existing_package.project, name: existing_package.name,
            version: existing_package.version)
        end

        it 'is invalid' do
          expect(new_package).not_to be_valid
        end
      end

      context 'when version is the same but name is different' do
        let(:new_package) do
          build(:cargo_package, project: existing_package.project, version: existing_package.version)
        end

        it 'is valid' do
          expect(new_package).to be_valid
        end
      end

      context 'when name is the same but version is different' do
        let(:new_package) do
          build(:cargo_package, project: existing_package.project, name: existing_package.name)
        end

        it 'is valid' do
          expect(new_package).to be_valid
        end
      end

      context 'when name and normalized version are the same (existing package has no build metadata)' do
        let(:new_package) do
          build(:cargo_package, project: existing_package.project, name: existing_package.name,
            version: '1.0.0+build999')
        end

        it 'is invalid because build metadata is ignored in uniqueness' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Package already exists')
        end
      end

      context 'when name and normalized version are the same (existing package has build metadata)' do
        let_it_be(:existing_package_with_build_metadata) { create(:cargo_package, version: '1.0.0+build999') }
        let_it_be(:existing_metadatum_with_build_metadata) do
          create(:cargo_metadatum, package: existing_package_with_build_metadata)
        end

        let(:new_package) do
          build(:cargo_package, project: existing_package_with_build_metadata.project,
            name: existing_package_with_build_metadata.name,
            version: '1.0.0')
        end

        it 'is invalid because build metadata is ignored in uniqueness' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Package already exists')
        end
      end

      context 'when name and normalized version are the same (both packages have build metadata)' do
        let_it_be(:existing_package_with_build_metadata) { create(:cargo_package, version: '1.0.0+build999') }
        let_it_be(:existing_metadatum_with_build_metadata) do
          create(:cargo_metadatum, package: existing_package_with_build_metadata)
        end

        let(:new_package) do
          build(:cargo_package, project: existing_package_with_build_metadata.project,
            name: existing_package_with_build_metadata.name,
            version: '1.0.0+build123')
        end

        it 'is invalid because build metadata is ignored in uniqueness' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Package already exists')
        end
      end

      context 'when normalized name and normalized version are same' do
        let_it_be(:existing_package_with_build_metadata) do
          create(:cargo_package, name: 'foo-bar', version: '1.0.0+build999')
        end

        let_it_be(:existing_metadatum_with_build_metadata) do
          create(:cargo_metadatum, package: existing_package_with_build_metadata)
        end

        let(:new_package) do
          build(:cargo_package, project: existing_package_with_build_metadata.project,
            name: 'foo_bar',
            version: '1.0.0+build123')
        end

        it 'is invalid' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Package already exists')
        end
      end

      context 'when package has no metadatum' do
        let_it_be(:existing_package_without_metadatum) { create(:cargo_package, name: 'foo-bar', version: '1.0.0') }

        let(:new_package) do
          build(:cargo_package, project: existing_package_without_metadatum.project, name: 'foo_bar',
            version: '1.0.0+build123')
        end

        it 'is valid because uniqueness check requires metadatum' do
          expect(new_package).to be_valid
        end
      end
    end

    describe '#version' do
      it_behaves_like 'validating version to be SemVer compliant for', :cargo_package
    end
  end

  describe '.cargo_package_already_taken?' do
    let_it_be(:project) { create(:project) }
    let(:package_name) { 'test-package' }
    let(:package_version) { '1.0.0+build123' }

    context 'when package exists with same normalized name and version' do
      let!(:existing_package) do
        create(:cargo_package, project: project, name: 'test_package', version: '1.0.0+build456')
      end

      let!(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      it 'returns true' do
        expect(described_class.cargo_package_already_taken?(project.id, package_name, package_version)).to be true
      end
    end

    context 'when package exists with different normalized name' do
      let!(:existing_package) do
        create(:cargo_package, project: project, name: 'different-package', version: '1.0.0+build456')
      end

      let!(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      it 'returns false' do
        expect(described_class.cargo_package_already_taken?(project.id, package_name, package_version)).to be false
      end
    end

    context 'when package exists with different normalized version' do
      let!(:existing_package) do
        create(:cargo_package, project: project, name: 'test_package', version: '2.0.0+build456')
      end

      let!(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      it 'returns false' do
        expect(described_class.cargo_package_already_taken?(project.id, package_name, package_version)).to be false
      end
    end

    context 'when package exists in different project' do
      let_it_be(:other_project) { create(:project) }
      let!(:existing_package) do
        create(:cargo_package, project: other_project, name: 'test_package', version: '1.0.0+build456')
      end

      let!(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

      it 'returns false' do
        expect(described_class.cargo_package_already_taken?(project.id, package_name, package_version)).to be false
      end
    end

    context 'when package has no metadatum' do
      let!(:existing_package) do
        create(:cargo_package, project: project, name: 'test_package', version: '1.0.0+build456')
      end

      it 'returns false' do
        expect(described_class.cargo_package_already_taken?(project.id, package_name, package_version)).to be false
      end
    end
  end
end
