# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::UpsertPackageReferenceService, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:conan_package_reference) { '1234567890abcdef1234567890abcdef12345678' }
  let_it_be(:recipe_revision) { create(:conan_recipe_revision, package: package) }

  let(:recipe_revision_id) { nil }

  shared_examples 'creates a new package reference' do
    it 'creates a new package reference with correct attributes' do
      expect { response }.to change { Packages::Conan::PackageReference.count }.by(1)

      package_reference = Packages::Conan::PackageReference.last
      expect(package_reference.reference).to eq(conan_package_reference)
      expect(package_reference.recipe_revision_id).to eq(recipe_revision_id)
      expect(response).to be_success
      expect(response[:package_reference_id]).to eq(package_reference.id)
    end
  end

  shared_examples 'returns existing package reference' do
    it 'returns the existing package reference without creating new one' do
      expect { response }.not_to change { Packages::Conan::PackageReference.count }

      expect(response).to be_success
      expect(response[:package_reference_id]).to eq(existing_package_reference.id)
    end
  end

  describe '#execute!', :aggregate_failures do
    subject(:response) { described_class.new(package, conan_package_reference, recipe_revision_id).execute! }

    context 'when the package reference doesn\'t exist' do
      context 'with no recipe revision' do
        it_behaves_like 'creates a new package reference'
      end

      context 'with recipe revision' do
        let(:recipe_revision_id) { recipe_revision.id }

        it_behaves_like 'creates a new package reference'
      end

      context 'when the package reference is invalid' do
        let(:conan_package_reference) { nil }

        it 'raises the error' do
          expect { response }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the package reference already exists' do
      context 'with no recipe revision' do
        let_it_be(:existing_package_reference) do
          create(:conan_package_reference, package: package, reference: conan_package_reference,
            recipe_revision: nil)
        end

        context 'when adding similar package reference with no recipe revision' do
          it_behaves_like 'returns existing package reference'
        end

        context 'when adding similar package reference with recipe revision' do
          let_it_be(:recipe_revision_id) { recipe_revision.id }

          it_behaves_like 'creates a new package reference'
        end
      end

      context 'with recipe revision' do
        let_it_be(:existing_package_reference) do
          create(:conan_package_reference, package: package, reference: conan_package_reference,
            recipe_revision: recipe_revision)
        end

        context 'when adding similar package reference with the same recipe revision' do
          let_it_be(:recipe_revision_id) { recipe_revision.id }

          it_behaves_like 'returns existing package reference'
        end

        context 'when adding similar package reference with no recipe revision' do
          it_behaves_like 'creates a new package reference'
        end
      end
    end
  end
end
