# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::UpdatePackageFromMetadataService, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let(:package) { create(:nuget_package, :processing, :with_symbol_package) }
  let(:package_file) { package.package_files.first }
  let(:service) { described_class.new(package_file) }
  let(:package_name) { 'DummyProject.DummyPackage' }
  let(:package_version) { '1.0.0' }
  let(:package_file_name) { 'dummyproject.dummypackage.1.0.0.nupkg' }

  shared_examples 'raising an' do |error_class|
    it "raises an #{error_class}" do
      expect { subject }.to raise_error(error_class)
    end
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'taking the lease' do
      before do
        allow(service).to receive(:lease_release?).and_return(false)
      end

      it 'takes the lease' do
        expect(service).to receive(:try_obtain_lease).and_call_original

        subject

        expect(service.exclusive_lease.exists?).to be_truthy
      end
    end

    shared_examples 'not updating the package if the lease is taken' do
      context 'without obtaining the exclusive lease' do
        let(:lease_key) { "packages:nuget:update_package_from_metadata_service:package:#{package_id}" }
        let(:metadata) { { package_name: package_name, package_version: package_version } }
        let(:package_from_package_file) { package_file.package }

        before do
          stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
          # to allow the above stub, we need to stub the metadata function as the
          # original implementation will try to get an exclusive lease on the
          # file in object storage
          allow(service).to receive(:metadata).and_return(metadata)
        end

        it 'does not update the package' do
          expect(service).to receive(:try_obtain_lease).and_call_original

          expect { subject }
            .to change { ::Packages::Package.count }.by(0)
            .and change { Packages::DependencyLink.count }.by(0)
          expect(package_file.reload.file_name).not_to eq(package_file_name)
          expect(package_file.package).to be_processing
          expect(package_file.package.reload.name).not_to eq(package_name)
          expect(package_file.package.version).not_to eq(package_version)
        end
      end
    end

    context 'with no existing package' do
      let(:package_id) { package.id }

      it 'updates package and package file' do
        expect { subject }
          .to change { ::Packages::Package.count }.by(1)
          .and change { Packages::Dependency.count }.by(1)
          .and change { Packages::DependencyLink.count }.by(1)
          .and change { ::Packages::Nuget::Metadatum.count }.by(0)

        expect(package.reload.name).to eq(package_name)
        expect(package.version).to eq(package_version)
        expect(package).to be_default
        expect(package_file.reload.file_name).to eq(package_file_name)
        # hard reset needed to properly reload package_file.file
        expect(Packages::PackageFile.find(package_file.id).file.size).not_to eq 0
      end

      it_behaves_like 'taking the lease'

      it_behaves_like 'not updating the package if the lease is taken'
    end

    context 'with existing package' do
      let!(:existing_package) { create(:nuget_package, project: package.project, name: package_name, version: package_version) }
      let(:package_id) { existing_package.id }

      it 'link existing package and updates package file' do
        expect(service).to receive(:try_obtain_lease).and_call_original

        expect { subject }
          .to change { ::Packages::Package.count }.by(-1)
          .and change { Packages::Dependency.count }.by(0)
          .and change { Packages::DependencyLink.count }.by(0)
          .and change { Packages::Nuget::DependencyLinkMetadatum.count }.by(0)
          .and change { ::Packages::Nuget::Metadatum.count }.by(0)
        expect(package_file.reload.file_name).to eq(package_file_name)
        expect(package_file.package).to eq(existing_package)
      end

      it_behaves_like 'taking the lease'

      it_behaves_like 'not updating the package if the lease is taken'
    end

    context 'with a nuspec file with metadata' do
      let(:nuspec_filepath) { 'packages/nuget/with_metadata.nuspec' }
      let(:expected_tags) { %w(foo bar test tag1 tag2 tag3 tag4 tag5) }

      before do
        allow_next_instance_of(Packages::Nuget::MetadataExtractionService) do |service|
          allow(service)
            .to receive(:nuspec_file_content).and_return(fixture_file(nuspec_filepath))
        end
      end

      it 'creates tags' do
        expect(service).to receive(:try_obtain_lease).and_call_original
        expect { subject }.to change { ::Packages::Tag.count }.by(8)
        expect(package.reload.tags.map(&:name)).to contain_exactly(*expected_tags)
      end

      context 'with existing package and tags' do
        let!(:existing_package) { create(:nuget_package, project: package.project, name: 'DummyProject.WithMetadata', version: '1.2.3') }
        let!(:tag1) { create(:packages_tag, package: existing_package, name: 'tag1') }
        let!(:tag2) { create(:packages_tag, package: existing_package, name: 'tag2') }
        let!(:tag3) { create(:packages_tag, package: existing_package, name: 'tag_not_in_metadata') }

        it 'creates tags and deletes those not in metadata' do
          expect(service).to receive(:try_obtain_lease).and_call_original
          expect { subject }.to change { ::Packages::Tag.count }.by(5)
          expect(existing_package.tags.map(&:name)).to contain_exactly(*expected_tags)
        end
      end

      it 'creates nuget metadatum' do
        expect { subject }
          .to change { ::Packages::Package.count }.by(1)
          .and change { ::Packages::Nuget::Metadatum.count }.by(1)

        metadatum = package_file.reload.package.nuget_metadatum
        expect(metadatum.license_url).to eq('https://opensource.org/licenses/MIT')
        expect(metadatum.project_url).to eq('https://gitlab.com/gitlab-org/gitlab')
        expect(metadatum.icon_url).to eq('https://opensource.org/files/osi_keyhole_300X300_90ppi_0.png')
      end

      context 'with too long url' do
        let_it_be(:too_long_url) { "http://localhost/#{'bananas' * 50}" }

        let(:metadata) { { package_name: package_name, package_version: package_version, license_url: too_long_url } }

        before do
          allow(service).to receive(:metadata).and_return(metadata)
        end

        it_behaves_like 'raising an', ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError
      end
    end

    context 'with nuspec file with dependencies' do
      let(:nuspec_filepath) { 'packages/nuget/with_dependencies.nuspec' }
      let(:package_name) { 'Test.Package' }
      let(:package_version) { '3.5.2' }
      let(:package_file_name) { 'test.package.3.5.2.nupkg' }

      before do
        allow_next_instance_of(Packages::Nuget::MetadataExtractionService) do |service|
          allow(service)
            .to receive(:nuspec_file_content).and_return(fixture_file(nuspec_filepath))
        end
      end

      it 'updates package and package file' do
        expect { subject }
          .to change { ::Packages::Package.count }.by(1)
          .and change { Packages::Dependency.count }.by(4)
          .and change { Packages::DependencyLink.count }.by(4)
          .and change { Packages::Nuget::DependencyLinkMetadatum.count }.by(2)

        expect(package.reload.name).to eq(package_name)
        expect(package.version).to eq(package_version)
        expect(package).to be_default
        expect(package_file.reload.file_name).to eq(package_file_name)
        # hard reset needed to properly reload package_file.file
        expect(Packages::PackageFile.find(package_file.id).file.size).not_to eq 0
      end
    end

    context 'with package file not containing a nuspec file' do
      before do
        allow_next_instance_of(Zip::File) do |file|
          allow(file).to receive(:glob).and_return([])
        end
      end

      it_behaves_like 'raising an', ::Packages::Nuget::MetadataExtractionService::ExtractionError
    end

    context 'with a symbol package' do
      let(:package_file) { package.package_files.last }
      let(:package_file_name) { 'dummyproject.dummypackage.1.0.0.snupkg' }

      context 'with no existing package' do
        let(:package_id) { package.id }

        it_behaves_like 'raising an', ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError
      end

      context 'with existing package' do
        let!(:existing_package) { create(:nuget_package, project: package.project, name: package_name, version: package_version) }
        let(:package_id) { existing_package.id }

        it 'link existing package and updates package file', :aggregate_failures do
          expect(service).to receive(:try_obtain_lease).and_call_original
          expect(::Packages::Nuget::SyncMetadatumService).not_to receive(:new)
          expect(::Packages::UpdateTagsService).not_to receive(:new)

          expect { subject }
            .to change { ::Packages::Package.count }.by(-1)
            .and change { Packages::Dependency.count }.by(0)
            .and change { Packages::DependencyLink.count }.by(0)
            .and change { Packages::Nuget::DependencyLinkMetadatum.count }.by(0)
            .and change { ::Packages::Nuget::Metadatum.count }.by(0)
          expect(package_file.reload.file_name).to eq(package_file_name)
          expect(package_file.package).to eq(existing_package)
        end

        it_behaves_like 'taking the lease'

        it_behaves_like 'not updating the package if the lease is taken'
      end
    end

    context 'with an invalid package name' do
      invalid_names = [
        '',
        'My/package',
        '../../../my_package',
        '%2e%2e%2fmy_package'
      ]

      invalid_names.each do |invalid_name|
        before do
          allow(service).to receive(:package_name).and_return(invalid_name)
        end

        it_behaves_like 'raising an', ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError
      end
    end

    context 'with an invalid package version' do
      invalid_versions = [
        '',
        '555',
        '1.2',
        '1./2.3',
        '../../../../../1.2.3',
        '%2e%2e%2f1.2.3'
      ]

      invalid_versions.each do |invalid_version|
        before do
          allow(service).to receive(:package_version).and_return(invalid_version)
        end

        it_behaves_like 'raising an', ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError
      end
    end
  end
end
