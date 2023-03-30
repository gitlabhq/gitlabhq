# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file) }
  let_it_be_with_reload(:package) do
    create(:debian_package, :processing, project: distribution.project, published_in: nil)
  end

  let(:distribution_name) { distribution.codename }
  let(:debian_file_metadatum) { package_file.debian_file_metadatum }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:package_file_id) { package_file.id }

    subject { worker.perform(package_file_id, distribution_name, component_name) }

    shared_examples 'returns early without error' do
      it 'returns early without error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect(::Packages::Debian::ProcessPackageFileService).not_to receive(:new)

        subject
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:case_name, :expected_file_type, :file_name, :component_name) do
      'with a deb'   | 'deb'  | 'libsample0_1.2.3~alpha2_amd64.deb'   | 'main'
      'with an udeb' | 'udeb' | 'sample-udeb_1.2.3~alpha2_amd64.udeb' | 'contrib'
      'with a ddeb'  | 'ddeb' | 'sample-ddeb_1.2.3~alpha2_amd64.ddeb' | 'main'
    end

    with_them do
      context 'with Debian package file' do
        let(:package_file) { package.package_files.with_file_name(file_name).first }

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

        context 'when the service raises an error' do
          let(:package_file) { package.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }

          it 'marks the package as errored', :aggregate_failures do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              instance_of(ArgumentError),
              package_file_id: package_file_id,
              distribution_name: distribution_name,
              component_name: component_name
            )
            expect { subject }
              .to not_change(Packages::Package, :count)
              .and not_change { Packages::PackageFile.count }
              .and not_change { package.package_files.count }
              .and change { package_file.reload.status }.to('error')
              .and change { package.reload.status }.from('processing').to('error')
          end
        end

        it_behaves_like 'an idempotent worker' do
          let(:job_args) { [package_file.id, distribution_name, component_name] }

          it 'sets the Debian file type as deb', :aggregate_failures do
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
              .and change { package.debian_publication }.from(nil)
              .and change { debian_file_metadatum.reload.file_type }.from('unknown').to(expected_file_type)
              .and change { debian_file_metadatum.component }.from(nil).to(component_name)
          end
        end
      end
    end

    context 'with already processed package file' do
      let_it_be(:package_file) { create(:debian_package_file) }

      let(:component_name) { 'main' }

      it_behaves_like 'returns early without error'
    end

    context 'with a deb' do
      let(:package_file) { package.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:component_name) { 'main' }

      context 'with non existing package file' do
        let(:package_file_id) { non_existing_record_id }

        it_behaves_like 'returns early without error'
      end

      context 'with nil package file id' do
        let(:package_file_id) { nil }

        it_behaves_like 'returns early without error'
      end
    end
  end
end
