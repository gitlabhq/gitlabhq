# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::FileMetadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package_file) }
  end

  describe 'validations' do
    let(:package_file) { create(:conan_package_file, :conan_recipe_file) }

    it { is_expected.to validate_presence_of(:package_file) }
    it { is_expected.to validate_presence_of(:recipe_revision) }

    describe '#recipe_revision' do
      it { is_expected.to allow_value("0").for(:recipe_revision) }
      it { is_expected.not_to allow_value(nil).for(:recipe_revision) }
    end

    describe '#package_revision_for_package_file' do
      context 'recipe file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

        it 'is valid with empty value' do
          conan_file_metadatum.package_revision = nil

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with value' do
          conan_file_metadatum.package_revision = '0'

          expect(conan_file_metadatum).to be_invalid
        end
      end

      context 'package file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

        it 'is valid with default value' do
          conan_file_metadatum.package_revision = '0'

          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid with non-default value' do
          conan_file_metadatum.package_revision = 'foo'

          expect(conan_file_metadatum).to be_invalid
        end
      end
    end

    describe '#conan_package_reference_for_package_file' do
      context 'recipe file' do
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :recipe_file, package_file: package_file) }

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
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

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
end
