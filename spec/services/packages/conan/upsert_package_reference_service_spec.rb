# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::UpsertPackageReferenceService, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package, without_package_files: true, package_references: []) }
  let_it_be(:conan_package_reference) { '1234567890abcdef1234567890abcdef12345678' }

  describe '#execute!', :aggregate_failures do
    subject(:response) { described_class.new(package, conan_package_reference).execute! }

    context 'when the package reference doesn\'t exist' do
      it 'creates the package reference' do
        expect { response }.to change { Packages::Conan::PackageReference.count }.by(1)

        package_reference = Packages::Conan::PackageReference.last
        expect(package_reference.reference).to eq(conan_package_reference)
        expect(response).to be_success
        expect(response[:package_reference_id]).to eq(package_reference.id)
      end

      context 'when the package reference is invalid' do
        let(:conan_package_reference) { nil }

        it 'raises the error' do
          expect { response }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the package reference already exists' do
      let_it_be(:package_reference) do
        create(:conan_package_reference, package: package, reference: conan_package_reference, recipe_revision: nil)
      end

      it 'returns existing package reference' do
        expect { response }.not_to change { Packages::Conan::PackageReference.count }

        expect(response).to be_success
        expect(response[:package_reference_id]).to eq(package_reference.id)
      end
    end
  end
end
