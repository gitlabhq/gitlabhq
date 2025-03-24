# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::RecipeRevision, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

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
      is_expected.to validate_uniqueness_of(:revision).scoped_to(:package_id).case_insensitive.on(%i[create update])
    end

    context 'when validating hex format and length' do
      where(:revision, :valid, :error_message) do
        OpenSSL::Digest.hexdigest('MD5', 'test string')  | true  | nil
        OpenSSL::Digest.hexdigest('SHA1', 'test string') | true  | nil
        'df28fd816be3a119de5ce4d374436b2g'               | false | 'Revision is invalid'
        ('a' * 41)                                       | false | 'Revision is invalid'
      end

      with_them do
        before do
          recipe_revision.revision = revision
        end

        if params[:valid]
          it { expect(recipe_revision).to be_valid }
        else
          it 'is invalid with the expected error message' do
            expect(recipe_revision).not_to be_valid
            expect(recipe_revision.errors).to contain_exactly(error_message)
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe '.order_by_id_desc' do
      let_it_be(:revision_1) { create(:conan_recipe_revision) }
      let_it_be(:revision_2) { create(:conan_recipe_revision) }

      subject { described_class.order_by_id_desc }

      it { is_expected.to eq([revision_2, revision_1]) }
    end
  end
end
