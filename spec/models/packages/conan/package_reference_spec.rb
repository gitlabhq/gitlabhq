# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageReference, type: :model, feature_category: :package_registry do
  describe 'associations' do
    it do
      is_expected.to belong_to(:package).class_name('Packages::Conan::Package').inverse_of(:conan_package_references)
    end

    it do
      is_expected.to belong_to(:recipe_revision).class_name('Packages::Conan::RecipeRevision')
        .inverse_of(:conan_package_references)
    end

    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    subject(:package_reference) { build(:conan_package_reference) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:reference) }

    it do
      # ignore case, same revision string with different case are converted to same hexa binary
      is_expected.to validate_uniqueness_of(:reference).scoped_to([:package_id,
        :recipe_revision_id]).case_insensitive
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
end
