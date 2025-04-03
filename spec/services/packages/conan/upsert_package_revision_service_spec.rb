# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::UpsertPackageRevisionService, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package, without_package_files: true) }
  let_it_be(:package_reference) { package.conan_package_references.first }
  let_it_be(:revision) { OpenSSL::Digest.hexdigest('MD5', 'valid_package_revision') }

  shared_examples 'creates a new package revision' do
    it 'creates a new package revision with correct attributes' do
      expect { response }.to change { Packages::Conan::PackageRevision.count }.by(1)

      package_revision = Packages::Conan::PackageRevision.last
      expect(package_revision.revision).to eq(revision)
      expect(package_revision.package_reference_id).to eq(package_reference.id)
      expect(package_revision.package_id).to eq(package.id)
      expect(package_revision.project_id).to eq(package.project_id)
      expect(response).to be_success
      expect(response[:package_revision_id]).to eq(package_revision.id)
    end
  end

  shared_examples 'returns existing package revision' do
    it 'returns the existing package revision without creating new one' do
      expect { response }.not_to change { Packages::Conan::PackageRevision.count }

      expect(response).to be_success
      expect(response[:package_revision_id]).to eq(existing_package_revision.id)
    end
  end

  describe '#execute!', :aggregate_failures do
    subject(:response) { described_class.new(package, package_reference.id, revision).execute! }

    context 'when the package revision doesn\'t exist' do
      it_behaves_like 'creates a new package revision'

      context 'when the package revision is invalid' do
        let(:revision) { nil }

        it 'raises the error' do
          expect { response }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the package revision already exists' do
      let_it_be(:existing_package_revision) do
        create(:conan_package_revision, package: package, package_reference: package_reference,
          revision: revision)
      end

      it_behaves_like 'returns existing package revision'
    end

    context 'when adding a package revision with same revision but different package reference' do
      let_it_be(:different_package_reference) { create(:conan_package_reference, package: package) }
      let_it_be(:existing_package_revision_with_different_ref) do
        create(:conan_package_revision, package: package, package_reference: different_package_reference,
          revision: revision)
      end

      it_behaves_like 'creates a new package revision'
    end
  end
end
