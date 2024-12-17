# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageReference, type: :model, feature_category: :package_registry do
  describe 'associations' do
    it 'belongs to package' do
      is_expected.to belong_to(:package).class_name('Packages::Conan::Package').inverse_of(:conan_package_references)
    end

    it 'belongs to recipe_revision' do
      is_expected.to belong_to(:recipe_revision).class_name('Packages::Conan::RecipeRevision')
        .inverse_of(:conan_package_references)
    end

    it { is_expected.to belong_to(:project) }

    it 'has many package_revisions' do
      is_expected.to have_many(:package_revisions).inverse_of(:package_reference)
        .class_name('Packages::Conan::PackageRevision')
    end

    it 'has many file_metadata' do
      is_expected.to have_many(:file_metadata).inverse_of(:package_reference)
        .class_name('Packages::Conan::FileMetadatum')
    end
  end

  describe 'validations' do
    subject(:package_reference) { build(:conan_package_reference) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:reference) }

    describe 'uniqueness of reference' do
      let_it_be(:conan_package) { create(:conan_package, without_package_files: true) }
      let_it_be(:existing_reference) { create(:conan_package_reference, package: conan_package) }

      context 'when recipe_revision_id is not nil' do
        it 'validates uniqueness scoped to package_id and recipe_revision_id', :aggregate_failures do
          duplicate_reference = build(:conan_package_reference, package_id: existing_reference.package_id,
            recipe_revision_id: existing_reference.recipe_revision_id, reference: existing_reference.reference)

          expect(duplicate_reference).not_to be_valid
          expect(duplicate_reference.errors[:reference]).to include('has already been taken')
        end

        it 'is valid if the reference is unique' do
          new_reference = build(:conan_package_reference, package_id: existing_reference.package_id,
            recipe_revision_id: existing_reference.recipe_revision_id,
            reference: Digest::SHA1.hexdigest('new_unique_reference')) # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant

          expect(new_reference).to be_valid
        end
      end

      context 'when recipe_revision_id is nil' do
        let_it_be(:existing_nil_revision_reference) do
          create(:conan_package_reference, package: conan_package, recipe_revision_id: nil)
        end

        it 'validates uniqueness scoped to package_id when both have nil recipe_revision_id', :aggregate_failures do
          duplicate_reference = build(:conan_package_reference, package_id: existing_nil_revision_reference.package_id,
            recipe_revision_id: nil, reference: existing_nil_revision_reference.reference)

          expect(duplicate_reference).not_to be_valid
          expect(duplicate_reference.errors[:reference]).to include('has already been taken')
        end

        it 'is valid if existing reference has a non-nil recipe_revision_id' do
          duplicate_reference = build(:conan_package_reference, package_id: existing_reference.package_id,
            recipe_revision_id: nil, reference: existing_reference.reference)

          expect(duplicate_reference).to be_valid
        end
      end
    end

    context 'on reference' do
      let(:invalid_reference) { 'a' * (Packages::Conan::PackageReference::REFERENCE_LENGTH_MAX + 1) }

      context 'when the length exceeds the maximum byte size' do
        it 'is not valid', :aggregate_failures do
          package_reference.reference = invalid_reference

          expect(package_reference).not_to be_valid
          expect(package_reference.errors[:reference]).to include(
            "is too long (#{Packages::Conan::PackageReference::REFERENCE_LENGTH_MAX + 1} B). " \
              "The maximum size is #{Packages::Conan::PackageReference::REFERENCE_LENGTH_MAX} B.")
        end
      end

      context 'when the length is within the byte size limit' do
        it 'is valid' do
          # package_reference is set correclty in the factory
          expect(package_reference).to be_valid
        end
      end
    end

    context 'on info' do
      subject(:package_reference) do
        pr = build(:conan_package_reference)
        pr.info = info if defined?(info)
        pr
      end

      it { is_expected.to be_valid }

      context 'with empty conan info' do
        let(:info) { {} }

        it { is_expected.to be_valid }
      end

      context 'with invalid conan info' do
        let(:info) { { invalid_field: 'some_value' } }

        it 'is invalid', :aggregate_failures do
          expect(package_reference).not_to be_valid
          expect(package_reference.errors[:info]).to include(
            'object at root is missing required properties: settings, requires, options')
        end
      end

      context 'when info size exceeds the maximum allowed size' do
        before do
          stub_const('Packages::Conan::PackageReference::MAX_INFO_SIZE', 1000)
        end

        let(:info) do
          {
            settings: { os: 'Linux', arch: 'x86_64' },
            requires: ['libA/1.0@user/testing'],
            options: { fPIC: true },
            otherProperties: 'a' * 1001 # Simulates large data
          }
        end

        it 'is invalid due to large size' do
          expect(package_reference).not_to be_valid
          expect(package_reference.errors[:info]).to include(
            'conaninfo is too large. Maximum size is 1000 characters'
          )
        end
      end
    end
  end

  describe '.for_package_id_and_reference' do
    let_it_be(:package_reference) { create(:conan_package_reference) }

    let(:reference) { package_reference.reference }

    subject { described_class.for_package_id_and_reference(package_reference.package_id, reference) }

    it { is_expected.to contain_exactly(package_reference) }

    context 'when no match is found' do
      let(:reference) { 'non_existent_reference' }

      it { is_expected.to be_empty }
    end
  end
end
