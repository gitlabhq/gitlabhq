# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::FileMetadatum, type: :model, feature_category: :package_registry do
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
        let(:conan_file_metadatum) { build(:conan_file_metadatum, :package_file, package_file: package_file) }

        it 'is valid when package_reference is present' do
          expect(conan_file_metadatum).to be_valid
        end

        it 'is invalid when package_reference is absent' do
          conan_file_metadatum.package_reference = nil

          expect(conan_file_metadatum).to be_invalid
        end
      end
    end

    describe '#package_revision' do
      context 'recipe file' do
        let(:conan_file_metadatum) do
          build(:conan_file_metadatum, :recipe_file, package_file: package_file,
            package_revision: build(:conan_package_revision))
        end

        it 'is invalid when package_revision is present' do
          expect(conan_file_metadatum).to be_invalid
          expect(conan_file_metadatum.errors[:package_revision]).to include('must be blank')
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

    describe '#ensure_recipe_revision_with_package_revision' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:package_revision) { build(:conan_package_revision) }
      let_it_be(:recipe_revision) { build(:conan_recipe_revision) }

      where(:package_revision_present, :recipe_revision_present, :error_field, :error_message) do
        true  | true  | nil               | nil
        true  | false | :recipe_revision  | 'must be present when package revision exists'
        false | true  | :package_revision | 'must be present when recipe revision exists'
        false | false | nil               | nil
      end

      with_them do
        let(:conan_file_metadatum) do
          build(:conan_file_metadatum, :package_file,
            package_file: package_file,
            package_revision: package_revision_present ? package_revision : nil,
            recipe_revision: recipe_revision_present ? recipe_revision : nil)
        end

        it 'validates recipe and package revision dependencies correctly' do
          expect(conan_file_metadatum.valid?).to eq(error_message.nil?)

          if error_message
            expect(conan_file_metadatum.errors[error_field]).to include(error_message)
          else
            expect(conan_file_metadatum.errors[:recipe_revision]).to be_empty
            expect(conan_file_metadatum.errors[:package_revision]).to be_empty
          end
        end
      end
    end
  end

  describe '#recipe_revision_value' do
    context 'when recipe_revision is present' do
      let(:revision) { 'some-revision-value' }

      let(:file_metadatum) do
        build(:conan_file_metadatum, recipe_revision: build(:conan_recipe_revision, revision: revision))
      end

      it 'returns the revision value' do
        expect(file_metadatum.recipe_revision_value).to eq(revision)
      end
    end

    context 'when recipe_revision is nil' do
      let(:file_metadatum) { build(:conan_file_metadatum) }

      it 'returns DEFAULT_REVISION' do
        expect(file_metadatum.recipe_revision_value).to eq(described_class::DEFAULT_REVISION)
      end
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
      let(:package_revision) { build(:conan_package_revision) }

      context 'when package_revision is nil' do
        it 'returns the default package revision value' do
          expect(conan_file_metadatum.package_revision_value).to eq(
            Packages::Conan::FileMetadatum::DEFAULT_REVISION)
        end
      end

      context 'when package_revision is present' do
        it 'returns the package revision value' do
          conan_file_metadatum.package_revision = package_revision

          expect(conan_file_metadatum.package_revision_value).to eq(package_revision.revision)
        end
      end
    end
  end

  describe '#package_reference_value' do
    let(:package_reference) { build(:conan_package_reference) }

    subject { conan_file_metadatum.package_reference_value }

    context 'when package_reference is present' do
      let(:conan_file_metadatum) do
        build(:conan_file_metadatum, :package_file, package_file: package_file, package_reference: package_reference)
      end

      it { is_expected.to eq(package_reference.reference) }
    end

    context 'when package_reference is nil' do
      let(:conan_file_metadatum) do
        build(:conan_file_metadatum, :recipe_file, package_file: package_file)
      end

      it { is_expected.to be_nil }
    end
  end
end
