# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::FileMetadatum, type: :model do
  let_it_be(:package_file) { build(:conan_package_file) }

  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }

    it 'belongs to recipe_revision' do
      is_expected.to belong_to(:recipe_revision).class_name('Packages::Conan::RecipeRevision')
        .inverse_of(:file_metadata)
    end

    it 'belongs to package_revision' do
      is_expected.to belong_to(:package_revision).class_name('Packages::Conan::PackageRevision')
        .inverse_of(:file_metadata)
    end

    it 'belongs to package_reference' do
      is_expected.to belong_to(:package_reference).class_name('Packages::Conan::PackageReference')
        .inverse_of(:file_metadata)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package_file) }
    it { is_expected.to validate_absence_of(:recipe_revision) }
    it { is_expected.to validate_absence_of(:package_revision) }

    describe '#conan_package_reference' do
      context 'recipe file' do
        let_it_be(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

        it 'is valid with empty value' do
          conan_file_metadatum.conan_package_reference = nil

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with value' do
          conan_file_metadatum.conan_package_reference = '123456789'

          expect(conan_file_metadatum).to be_invalid
        end
      end

      context 'package file' do
        let_it_be(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

        it 'is valid with acceptable value' do
          conan_file_metadatum.conan_package_reference = '123456asdf'

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with invalid value' do
          conan_file_metadatum.conan_package_reference = 'foo@bar'

          expect(conan_file_metadatum).to be_invalid
        end

        it 'is invalid when nil' do
          conan_file_metadatum.conan_package_reference = nil

          expect(conan_file_metadatum).to be_invalid
        end
      end
    end

    describe '#package_reference' do
      let_it_be(:package_reference) { build(:conan_package_reference) }

      context 'recipe file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

        it 'is valid when package_reference is absent' do
          conan_file_metadatum.package_reference = nil

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid when package_reference is present' do
          conan_file_metadatum.package_reference = package_reference

          expect(conan_file_metadatum).to be_invalid
        end
      end

      context 'package file' do
        context 'on create' do
          let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

          it 'is valid when package_reference is present' do
            conan_file_metadatum.package_reference = package_reference

            expect(conan_file_metadatum).to be_valid
          end

          it 'is invalid when package_reference is absent' do
            conan_file_metadatum.package_reference = nil

            expect(conan_file_metadatum).to be_invalid
          end
        end

        context 'on update' do
          let_it_be_with_reload(:existing_metadatum) do
            create(:conan_file_metadatum, :package_file, package_file: package_file)
          end

          it 'is valid when package_reference is absent' do
            existing_metadatum.package_reference = nil

            expect(existing_metadatum).to be_valid
          end

          it 'is valid when package_reference is present' do
            existing_metadatum.package_reference = package_reference

            expect(existing_metadatum).to be_valid
          end
        end
      end
    end

    describe '#conan_package_type' do
      it 'validates package of type conan' do
        package = build('package')
        package_file = build('package_file', package: package)
        conan_file_metadatum = build('conan_file_metadatum', package_file: package_file)

        expect(conan_file_metadatum).not_to be_valid
        expect(conan_file_metadatum.errors.to_a).to contain_exactly('Package type must be Conan')
      end
    end
  end

  describe '#recipe_revision_value' do
    let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

    it 'returns the default recipe revision value' do
      expect(conan_file_metadatum.recipe_revision_value).to eq(
        Packages::Conan::FileMetadatum::DEFAULT_REVISION)
    end
  end

  describe '#package_revision_value' do
    context 'recipe file' do
      let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

      it 'returns nil' do
        expect(conan_file_metadatum.package_revision_value).to be_nil
      end
    end

    context 'package file' do
      let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

      it 'returns the default package revision value' do
        expect(conan_file_metadatum.package_revision_value).to eq(
          Packages::Conan::FileMetadatum::DEFAULT_REVISION)
      end
    end
  end
end
