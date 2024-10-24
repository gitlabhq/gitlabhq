# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::RecipeRevision, type: :model, feature_category: :package_registry do
  describe 'associations' do
    it 'belongs to package' do
      is_expected.to belong_to(:package).class_name('Packages::Conan::Package').inverse_of(:conan_recipe_revisions)
    end

    it { is_expected.to belong_to(:project) }

    it 'has many conan_package_references' do
      is_expected.to have_many(:conan_package_references).inverse_of(:recipe_revision)
        .class_name('Packages::Conan::PackageReference')
    end

    it 'has many file_metadata' do
      is_expected.to have_many(:file_metadata).inverse_of(:recipe_revision)
        .class_name('Packages::Conan::FileMetadatum')
    end
  end

  describe 'validations' do
    subject(:recipe_revision) { build(:conan_recipe_revision) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:revision) }

    it 'has unique revision scoped to package_id' do
      # ignore case, same revision string with different case are converted to same hexa binary
      is_expected.to validate_uniqueness_of(:revision).scoped_to(:package_id).case_insensitive
    end

    context 'when validating the byte size of revision' do
      let(:invalid_revision) { 'a' * (Packages::Conan::RecipeRevision::REVISION_LENGTH_MAX + 1) }

      it 'is not valid if revision exceeds maximum byte size', :aggregate_failures do
        recipe_revision.revision = invalid_revision

        expect(recipe_revision).not_to be_valid
        expect(recipe_revision.errors[:revision]).to include(
          "is too long (#{Packages::Conan::RecipeRevision::REVISION_LENGTH_MAX + 1} B). " \
            "The maximum size is #{Packages::Conan::RecipeRevision::REVISION_LENGTH_MAX} B.")
      end

      it 'is valid if revision is within byte size limit' do
        # recipe revision is set correclty in the factory
        expect(recipe_revision).to be_valid
      end
    end
  end
end
