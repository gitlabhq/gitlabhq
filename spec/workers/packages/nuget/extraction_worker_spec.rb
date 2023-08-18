# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::ExtractionWorker, type: :worker, feature_category: :package_registry do
  describe '#perform' do
    let!(:package) { create(:nuget_package) }
    let(:package_file) { package.package_files.first }
    let(:package_file_id) { package_file.id }

    let_it_be(:package_name) { 'DummyProject.DummyPackage' }
    let_it_be(:package_version) { '1.0.0' }

    subject { described_class.new.perform(package_file_id) }

    shared_examples 'handling error' do |error_message:,
      error_class: ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError|
      it 'updates package status to error', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(error_class),
          {
            package_file_id: package_file.id,
            project_id: package.project_id
          }
        )

        subject

        expect(package.reload).to be_error
        expect(package.status_message).to match(error_message)
      end
    end

    context 'with valid package file' do
      it 'updates package and package file' do
        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
      end

      context 'with exisiting package' do
        let!(:existing_package) { create(:nuget_package, project: package.project, name: package_name, version: package_version) }

        it 'reuses existing package and updates package file' do
          expect { subject }
            .to change { Packages::Package.count }.by(-1)
            .and change { existing_package.reload.package_files.count }.by(1)
            .and not_change { Packages::PackageFile.count }
        end
      end
    end

    context 'with invalid package file id' do
      let(:package_file_id) { 5555 }

      it "doesn't update package and package file" do
        expect { subject }
          .to not_change { package.reload.name }
          .and not_change { package.version }
          .and not_change { package_file.reload.file_name }
      end
    end

    context 'with controlled errors' do
      context 'with package file not containing a nuspec file' do
        before do
          allow_any_instance_of(Zip::File).to receive(:glob).and_return([])
        end

        it_behaves_like 'handling error',
          error_class: ::Packages::Nuget::ExtractMetadataFileService::ExtractionError,
          error_message: 'nuspec file not found'
      end

      context 'with invalid metadata' do
        shared_context 'with a blank attribute' do
          before do
            allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
              allow(service).to receive(attribute).and_return('')
            end
          end
        end

        context 'with a blank package name' do
          include_context 'with a blank attribute' do
            let(:attribute) { :package_name }

            it_behaves_like 'handling error', error_message: /not found in metadata/
          end
        end

        context 'with package with an invalid package name' do
          invalid_names = [
            'My/package',
            '../../../my_package',
            '%2e%2e%2fmy_package'
          ]

          invalid_names.each do |invalid_name|
            context "with #{invalid_name}" do
              before do
                allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
                  allow(service).to receive(:package_name).and_return(invalid_name)
                end
              end

              it_behaves_like 'handling error', error_message: 'Validation failed: Name is invalid'
            end
          end
        end

        context 'with package with a blank package version' do
          include_context 'with a blank attribute' do
            let(:attribute) { :package_version }

            it_behaves_like 'handling error', error_message: /not found in metadata/
          end
        end

        context 'with package with an invalid package version' do
          invalid_versions = [
            '555',
            '1./2.3',
            '../../../../../1.2.3',
            '%2e%2e%2f1.2.3'
          ]

          invalid_versions.each do |invalid_version|
            context "with #{invalid_version}" do
              before do
                allow_next_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService) do |service|
                  allow(service).to receive(:package_version).and_return(invalid_version)
                end
              end

              it_behaves_like 'handling error', error_message: 'Validation failed: Version is invalid'
            end
          end
        end
      end

      context 'handling a Zip::Error exception' do
        before do
          allow_any_instance_of(::Packages::UpdatePackageFileService).to receive(:execute).and_raise(::Zip::Error)
        end

        it_behaves_like 'handling error',
          error_class: ::Packages::Nuget::UpdatePackageFromMetadataService::ZipError,
          error_message: 'Could not open the .nupkg file'
      end
    end

    context 'with uncontrolled errors' do
      before do
        allow_any_instance_of(::Packages::Nuget::UpdatePackageFromMetadataService).to receive(:execute).and_raise(StandardError.new('Boom'))
      end

      it_behaves_like 'handling error', error_class: StandardError, error_message: 'Unexpected error: StandardError'
    end
  end
end
