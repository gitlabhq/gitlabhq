# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageRevision, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to be_a(Packages::Conan::PackageFileable) }

  describe 'associations' do
    it 'belongs to package' do
      is_expected.to belong_to(:package).class_name('Packages::Conan::Package').inverse_of(:conan_package_revisions)
    end

    it 'belongs to package_reference' do
      is_expected.to belong_to(:package_reference).class_name('Packages::Conan::PackageReference')
        .inverse_of(:package_revisions)
    end

    it { is_expected.to belong_to(:project) }

    it 'has many file_metadata' do
      is_expected.to have_many(:file_metadata).inverse_of(:package_revision)
        .class_name('Packages::Conan::FileMetadatum')
    end
  end

  describe 'validations' do
    subject(:package_revision) { build(:conan_package_revision) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:package_reference) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:revision) }

    it 'has unique revision scoped to package_id and package_reference_id' do
      # ignore case, same revision string with different case are converted to same hexa binary
      is_expected.to validate_uniqueness_of(:revision).scoped_to([:package_id, :package_reference_id]).case_insensitive
        .on(%i[create update])
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
          package_revision.revision = revision
        end

        if params[:valid]
          it { expect(package_revision).to be_valid }
        else
          it 'is invalid with the expected error message' do
            expect(package_revision).not_to be_valid
            expect(package_revision.errors).to contain_exactly(error_message)
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe '.order_by_id_desc' do
      let_it_be(:revision_1) { create(:conan_package_revision) }
      let_it_be(:revision_2) { create(:conan_package_revision) }

      subject { described_class.order_by_id_desc }

      it { is_expected.to eq([revision_2, revision_1]) }
    end

    describe '.by_recipe_revision_and_package_reference' do
      let_it_be(:package) { create(:conan_package) }
      let_it_be(:recipe_revision) { package.conan_recipe_revisions.first }
      let_it_be(:package_reference) { package.conan_package_references.first }
      let_it_be(:package_revision) { package.conan_package_revisions.first }

      let(:revision_value) { recipe_revision.revision }
      let(:reference_value) { package_reference.reference }

      subject { described_class.by_recipe_revision_and_package_reference(revision_value, reference_value) }

      it { is_expected.to contain_exactly(package_revision) }

      context 'when recipe revision does not match' do
        it 'returns empty relation' do
          expect(described_class.by_recipe_revision_and_package_reference('nonexistent', reference_value)).to be_empty
        end
      end

      context 'when package reference does not match' do
        it 'returns empty relation' do
          expect(described_class.by_recipe_revision_and_package_reference(revision_value, 'nonexistent')).to be_empty
        end
      end
    end
  end
end
