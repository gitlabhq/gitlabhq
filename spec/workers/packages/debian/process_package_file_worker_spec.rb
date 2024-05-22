# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  shared_examples 'returns early without error' do
    it 'returns early without error' do
      expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
      expect(::Packages::Debian::ProcessPackageFileService).not_to receive(:new)

      subject
    end
  end

  let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file) }
  let_it_be_with_reload(:incoming) { create(:debian_incoming, project: distribution.project) }
  let_it_be_with_reload(:temp_with_changes) { create(:debian_temporary_with_changes, project: distribution.project) }
  let_it_be_with_reload(:temp_with_files) { create(:debian_temporary_with_files, project: distribution.project) }

  describe '#perform' do
    let(:package) { temp_with_files }
    let(:package_file) { package.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
    let(:debian_file_metadatum) { package_file.debian_file_metadatum }
    let(:worker) { described_class.new }

    let(:package_file_id) { package_file.id }
    let(:distribution_name) { distribution.codename }
    let(:component_name) { 'main' }

    subject { worker.perform(package_file_id, distribution_name, component_name) }

    shared_context 'with changes file' do
      let(:package) { temp_with_changes }
      let(:package_file) { package.package_files.first }
      let(:distribution_name) { nil }
      let(:component_name) { nil }

      before do
        distribution.update! suite: 'unstable'
      end
    end

    context 'with non existing package file' do
      let(:package_file_id) { non_existing_record_id }

      it_behaves_like 'returns early without error'
    end

    context 'with nil package file id' do
      let(:package_file_id) { nil }

      it_behaves_like 'returns early without error'
    end

    context 'with already processed package file' do
      let_it_be(:package_file) { create(:debian_package_file) }

      it_behaves_like 'returns early without error'
    end

    context 'with mocked service' do
      it 'calls ProcessPackageFileService' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect_next_instance_of(::Packages::Debian::ProcessPackageFileService) do |service|
          expect(service).to receive(:execute)
            .with(no_args)
        end

        subject
      end
    end

    shared_examples 'handling error' do |error_message:, error_class:|
      it 'marks the package as errored', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(error_class),
          package_file_id: package_file_id,
          project_id: package.project_id,
          distribution_name: distribution_name,
          component_name: component_name
        )
        expect { subject }
          .to not_change(Packages::Package, :count)
          .and not_change { Packages::PackageFile.count }
          .and not_change { package.package_files.count }
          .and change { package_file.reload.status }.to('error')
          .and change { package.reload.status }.from('processing').to('error')
          .and change { package.status_message }.to(error_message)
      end
    end

    context 'with controlled errors' do
      context 'with a package file' do
        context 'when component name is blank' do
          let(:component_name) { '' }

          it_behaves_like 'handling error',
            error_message: 'missing component name',
            error_class: ArgumentError
        end

        context 'when distribution name is blank' do
          let(:distribution_name) { '' }

          it_behaves_like 'handling error',
            error_message: 'missing distribution name',
            error_class: ArgumentError
        end

        context 'when package file is not deb, ddeb or udeb' do
          let(:package_file) { package.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }

          it_behaves_like 'handling error',
            error_message: 'invalid package file type: source',
            error_class: ArgumentError
        end
      end

      context 'with changes file' do
        include_context 'with changes file'

        let(:file_metadata_source) { 'src' }
        let(:file_metadata_version) { '0.1' }
        let(:file_metadata_distribution) { 'Breezy Badger' }
        let(:file_metadata) do
          {
            fields: {
              'Source' => file_metadata_source,
              'Version' => file_metadata_version,
              'Distribution' => file_metadata_distribution
            }
          }
        end

        context 'when component name is blank' do
          let(:component_name) { '' }

          it_behaves_like 'handling error',
            error_message: 'unwanted component name',
            error_class: ArgumentError
        end

        context 'with distribution name is blank' do
          let(:distribution_name) { '' }

          it_behaves_like 'handling error',
            error_message: 'unwanted distribution name',
            error_class: ArgumentError
        end

        context 'with missing file metadata fields' do
          before do
            allow_next_instance_of(::Packages::Debian::ExtractChangesMetadataService) do |instance|
              allow(instance).to receive(:execute).and_return(file_metadata)
            end
          end

          context 'when source field is missing' do
            before do
              file_metadata[:fields].delete('Source')
            end

            it_behaves_like 'handling error',
              error_message: 'missing Source field',
              error_class: ArgumentError
          end

          context 'when Version field is missing' do
            before do
              file_metadata[:fields].delete('Version')
            end

            it_behaves_like 'handling error',
              error_message: 'missing Version field',
              error_class: ArgumentError
          end

          context 'when Distribution field is missing' do
            before do
              file_metadata[:fields].delete('Distribution')
            end

            it_behaves_like 'handling error',
              error_message: 'missing Distribution field',
              error_class: ArgumentError
          end
        end
      end
    end

    context 'with uncontrolled errors' do
      before do
        allow_next_instance_of(::Packages::Debian::ProcessPackageFileService) do |instance|
          allow(instance).to receive(:execute).and_raise(StandardError.new('Boom'))
        end
      end

      it_behaves_like 'handling error',
        error_message: 'Unexpected error: StandardError',
        error_class: StandardError
    end

    context 'with correct job arguments' do
      let(:job_args) { [package_file.id, distribution_name, component_name] }

      it_behaves_like 'an idempotent worker'

      context 'with a Debian changes file' do
        include_context 'with changes file'

        it 'sets the Debian file type to changes', :aggregate_failures do
          expect(::Packages::Debian::GenerateDistributionWorker)
            .to receive(:perform_async).with(:project, distribution.id)
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          # Using subject inside this block will process the job multiple times
          expect { subject }
            .to not_change(Packages::Package, :count)
            .and not_change(Packages::PackageFile, :count)
            .and change { Packages::Debian::Publication.count }.by(1)
            .and change { package.package_files.count }.from(1).to(8)
            .and change { package.reload.name }.to('sample')
            .and change { package.version }.to('1.2.3~alpha2')
            .and change { package.status }.from('processing').to('default')
            .and change { package.publication }.from(nil)
            .and change { debian_file_metadatum.reload.file_type }.from('unknown').to('changes')
            .and not_change { debian_file_metadatum.component }
        end
      end

      context 'with Debian files' do
        using RSpec::Parameterized::TableSyntax

        where(:case_name, :expected_file_type, :file_name, :component_name) do
          'with a deb'   | 'deb'  | 'libsample0_1.2.3~alpha2_amd64.deb'   | 'main'
          'with an udeb' | 'udeb' | 'sample-udeb_1.2.3~alpha2_amd64.udeb' | 'contrib'
          'with a ddeb'  | 'ddeb' | 'sample-ddeb_1.2.3~alpha2_amd64.ddeb' | 'main'
        end

        with_them do
          let(:package_file) { package.package_files.with_file_name(file_name).first }
          let(:job_args) { [package_file.id, distribution_name, component_name] }

          it 'sets the correct Debian file type', :aggregate_failures do
            expect(::Packages::Debian::GenerateDistributionWorker)
              .to receive(:perform_async).with(:project, distribution.id)
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

            # Using subject inside this block will process the job multiple times
            expect { subject }
              .to not_change(Packages::Package, :count)
              .and not_change(Packages::PackageFile, :count)
              .and change { Packages::Debian::Publication.count }.by(1)
              .and not_change(package.package_files, :count)
              .and change { package.reload.name }.to('sample')
              .and change { package.version }.to('1.2.3~alpha2')
              .and change { package.status }.from('processing').to('default')
              .and change { package.publication }.from(nil)
              .and change { debian_file_metadatum.reload.file_type }.from('unknown').to(expected_file_type)
              .and change { debian_file_metadatum.component }.from(nil).to(component_name)
          end
        end
      end
    end
  end
end
