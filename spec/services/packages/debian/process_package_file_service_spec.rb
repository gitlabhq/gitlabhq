# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileService, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:distribution) { create(:debian_project_distribution, :with_file, suite: 'unstable') }

  let(:debian_file_metadatum) { package_file.debian_file_metadatum }
  let(:service) { described_class.new(package_file, distribution_name, component_name) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { service.execute }

    shared_examples 'common validations' do
      context 'with package file without Debian metadata' do
        let!(:package_file) { create(:debian_package_file, without_loaded_metadatum: true) }

        let(:expected_error) { ArgumentError }
        let(:expected_message) { 'package file without Debian metadata' }

        it_behaves_like 'raises error'
      end

      context 'with already processed package file' do
        let!(:package_file) { create(:debian_package_file) }

        let(:expected_error) { ArgumentError }
        let(:expected_message) { 'already processed package file' }

        it_behaves_like 'raises error'
      end

      context 'without a distribution' do
        let(:expected_error) { ActiveRecord::RecordNotFound }
        let(:expected_message) { /^Couldn't find Packages::Debian::ProjectDistribution with / }

        before do
          # Workaround ActiveRecord cache
          Packages::Debian::ProjectDistribution.find(distribution.id).delete
        end

        it_behaves_like 'raises error'
      end

      context 'when there is a matching published package in another distribution' do
        let!(:matching_package) do
          create(
            :debian_package,
            project: distribution.project,
            name: 'sample',
            version: '1.2.3~alpha2'
          )
        end

        let(:expected_error) { ArgumentError }

        let(:expected_message) do
          "Debian package sample 1.2.3~alpha2 exists in distribution #{matching_package.distribution.codename}"
        end

        it_behaves_like 'raises error'
      end
    end

    shared_examples 'raises error' do
      it 'raises error', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change { Packages::Debian::Publication.count }
          .and not_change(package.package_files, :count)
          .and not_change { package.reload.name }
          .and not_change { package.version }
          .and not_change { package.status }
          .and not_change { debian_file_metadatum&.reload&.file_type }
          .and not_change { debian_file_metadatum&.component }
          .and raise_error(expected_error, expected_message)
      end
    end

    shared_examples 'does nothing' do
      it 'does nothing', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change { Packages::Debian::Publication.count }
          .and not_change(package.package_files, :count)
          .and not_change { package.reload.name }
          .and not_change { package.version }
          .and not_change { package.status }
          .and not_change { debian_file_metadatum&.reload&.file_type }
          .and not_change { debian_file_metadatum&.component }
      end
    end

    shared_examples 'updates package and changes file' do
      it 'updates package and changes file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker)
          .to receive(:perform_async).with(:project, distribution.id)
        expect { subject }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and change { Packages::Debian::Publication.count }.by(1)
          .and change { package.package_files.count }.from(1).to(8)
          .and change { package.reload.name }.to('sample')
          .and change { package.version }.to('1.2.3~alpha2')
          .and change { package.status }.from('processing').to('default')
          .and change { package.publication }.from(nil)
          .and change { debian_file_metadatum.file_type }.from('unknown').to('changes')
          .and not_change { debian_file_metadatum.component }
      end
    end

    shared_examples 'updates package and package file' do
      it 'updates package and package file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker)
          .to receive(:perform_async).with(:project, distribution.id)
        expect { subject }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and change { Packages::Debian::Publication.count }.by(1)
          .and not_change(package.package_files, :count)
          .and change { package.reload.name }.to('sample')
          .and change { package.version }.to('1.2.3~alpha2')
          .and change { package.status }.from('processing').to('default')
          .and change { package.publication }.from(nil)
          .and change { debian_file_metadatum.file_type }.from('unknown').to(expected_file_type)
          .and change { debian_file_metadatum.component }.from(nil).to(component_name)
      end
    end

    context 'with a changes file' do
      let!(:incoming) { create(:debian_incoming, project: distribution.project) }
      let!(:temporary_with_changes) { create(:debian_temporary_with_changes, project: distribution.project) }
      # Reload factory to reset associations cache for package files
      let(:package) { temporary_with_changes.reload }

      let(:package_file) { temporary_with_changes.package_files.first }
      let(:distribution_name) { nil }
      let(:component_name) { nil }

      it_behaves_like 'common validations'

      context 'with distribution_name' do
        let(:distribution_name) { distribution.codename }
        let(:expected_error) { ArgumentError }
        let(:expected_message) { 'unwanted distribution name' }

        it_behaves_like 'raises error'
      end

      context 'with component_name' do
        let(:component_name) { 'main' }
        let(:expected_error) { ArgumentError }
        let(:expected_message) { 'unwanted component name' }

        it_behaves_like 'raises error'
      end

      context 'with crafted file_metadata' do
        let(:complete_file_metadata) do
          {
            file_type: :changes,
            fields: {
              'Source' => 'abc',
              'Version' => '1.0',
              'Distribution' => 'sid'
            }
          }
        end

        let(:expected_error) { ArgumentError }

        before do
          allow_next_instance_of(::Packages::Debian::ExtractChangesMetadataService) do |extract_changes_metadata_svc|
            allow(extract_changes_metadata_svc).to receive(:execute).and_return(file_metadata)
          end
        end

        context 'with missing Source field' do
          let(:file_metadata) { complete_file_metadata.tap { |m| m[:fields].delete 'Source' } }
          let(:expected_message) { 'missing Source field' }

          it_behaves_like 'raises error'
        end

        context 'with missing Version field' do
          let(:file_metadata) { complete_file_metadata.tap { |m| m[:fields].delete 'Version' } }
          let(:expected_message) { 'missing Version field' }

          it_behaves_like 'raises error'
        end

        context 'with missing Distribution field' do
          let(:file_metadata) { complete_file_metadata.tap { |m| m[:fields].delete 'Distribution' } }
          let(:expected_message) { 'missing Distribution field' }

          it_behaves_like 'raises error'
        end
      end

      context 'when lease is already taken' do
        before do
          stub_exclusive_lease_taken(
            "packages:debian:process_package_file_service:#{distribution.project_id}_sample_1.2.3~alpha2",
            timeout: Packages::Debian::ProcessPackageFileService::DEFAULT_LEASE_TIMEOUT)
        end

        it_behaves_like 'does nothing'
      end

      context 'when there is no matching published package' do
        it_behaves_like 'updates package and changes file'
      end

      context 'when there is a matching published package' do
        let!(:matching_package) do
          create(
            :debian_package,
            project: distribution.project,
            published_in: distribution,
            name: 'sample',
            version: '1.2.3~alpha2'
          )
        end

        it 'reuses existing package and update package file', :aggregate_failures do
          expect(::Packages::Debian::GenerateDistributionWorker)
            .to receive(:perform_async).with(:project, distribution.id)
          expect { subject }
            .to change { Packages::Package.count }.from(3).to(2)
            .and not_change { Packages::PackageFile.count }
            .and not_change(Packages::Debian::Publication, :count)
            .and change { package.package_files.count }.from(1).to(0)
            .and change { incoming.package_files.count }.from(7).to(0)
            .and change { matching_package.package_files.count }.from(7).to(15)
            .and change { package_file.package }.from(package).to(matching_package)
            .and not_change(matching_package, :name)
            .and not_change(matching_package, :version)
            .and change { debian_file_metadatum.file_type }.from('unknown').to('changes')
            .and not_change { debian_file_metadatum.component }

          expect { package.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when there is a matching published package pending destruction' do
        let!(:matching_package) do
          create(
            :debian_package,
            :pending_destruction,
            project: distribution.project,
            published_in: distribution,
            name: 'sample',
            version: '1.2.3~alpha2'
          )
        end

        it_behaves_like 'updates package and changes file'
      end
    end

    context 'with a package file' do
      let!(:temporary_with_files) { create(:debian_temporary_with_files, project: distribution.project) }
      # Reload factory to reset associations cache for package files
      let(:package) { temporary_with_files.reload }

      let(:package_file) { package.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:distribution_name) { distribution.codename }
      let(:component_name) { 'main' }

      where(:case_name, :expected_file_type, :file_name, :component_name) do
        'with a deb'   | 'deb'  | 'libsample0_1.2.3~alpha2_amd64.deb'   | 'main'
        'with an udeb' | 'udeb' | 'sample-udeb_1.2.3~alpha2_amd64.udeb' | 'contrib'
        'with an ddeb' | 'ddeb' | 'sample-ddeb_1.2.3~alpha2_amd64.ddeb' | 'main'
      end

      with_them do
        context 'with Debian package file' do
          let(:package_file) { package.package_files.with_file_name(file_name).first }

          it_behaves_like 'common validations'

          context 'without distribution name' do
            let(:distribution_name) { '' }
            let(:expected_error) { ArgumentError }
            let(:expected_message) { 'missing distribution name' }

            it_behaves_like 'raises error'
          end

          context 'without component name' do
            let(:component_name) { '' }
            let(:expected_error) { ArgumentError }
            let(:expected_message) { 'missing component name' }

            it_behaves_like 'raises error'
          end

          context 'with invalid package file type' do
            let(:package_file) { package.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }
            let(:expected_error) { ArgumentError }
            let(:expected_message) { 'invalid package file type: source' }

            it_behaves_like 'raises error'
          end

          context 'when lease is already taken' do
            before do
              stub_exclusive_lease_taken(
                "packages:debian:process_package_file_service:#{distribution.project_id}_sample_1.2.3~alpha2",
                timeout: Packages::Debian::ProcessPackageFileService::DEFAULT_LEASE_TIMEOUT)
            end

            it_behaves_like 'does nothing'
          end

          context 'when there is no matching published package' do
            it_behaves_like 'updates package and package file'

            context 'with suite as distribution name' do
              let(:distribution_name) { distribution.suite }

              it_behaves_like 'updates package and package file'
            end
          end

          context 'when there is a matching published package' do
            let!(:matching_package) do
              create(
                :debian_package,
                project: distribution.project,
                published_in: distribution,
                name: 'sample',
                version: '1.2.3~alpha2'
              )
            end

            it 'reuses existing package and update package file', :aggregate_failures do
              expect(::Packages::Debian::GenerateDistributionWorker)
                .to receive(:perform_async).with(:project, distribution.id)
              expect { subject }
                .to change { Packages::Package.count }.from(2).to(1)
                .and change { Packages::PackageFile.count }.from(14).to(8)
                .and not_change(Packages::Debian::Publication, :count)
                .and change { package.package_files.count }.from(7).to(0)
                .and change { package_file.package }.from(package).to(matching_package)
                .and not_change(matching_package, :name)
                .and not_change(matching_package, :version)
                .and change { debian_file_metadatum.file_type }.from('unknown').to(expected_file_type)
                .and change { debian_file_metadatum.component }.from(nil).to(component_name)

              expect { package.reload }
                .to raise_error(ActiveRecord::RecordNotFound)
            end
          end

          context 'when there is a matching published package pending destruction' do
            let!(:matching_package) do
              create(
                :debian_package,
                :pending_destruction,
                project: distribution.project,
                published_in: distribution,
                name: 'sample',
                version: '1.2.3~alpha2'
              )
            end

            it_behaves_like 'updates package and package file'
          end
        end
      end
    end
  end

  describe '#lease_key' do
    let(:prefix) { 'packages:debian:process_package_file_service' }

    subject { service.send(:lease_key) }

    context 'with a changes file' do
      let!(:incoming) { create(:debian_incoming, project: distribution.project) }
      let!(:temporary_with_changes) { create(:debian_temporary_with_changes, project: distribution.project) }
      # Reload factory to reset associations cache for package files
      let(:package) { temporary_with_changes.reload }

      let(:package_file) { temporary_with_changes.package_files.first }
      let(:distribution_name) { nil }
      let(:component_name) { nil }

      it { is_expected.to eq("#{prefix}:#{distribution.project_id}_sample_1.2.3~alpha2") }
    end

    context 'with a package file' do
      let!(:temporary_with_files) { create(:debian_temporary_with_files, project: distribution.project) }
      # Reload factory to reset associations cache for package files
      let(:package) { temporary_with_files.reload }

      let(:package_file) { package.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:distribution_name) { distribution.codename }
      let(:component_name) { 'main' }

      it { is_expected.to eq("#{prefix}:#{distribution.project_id}_sample_1.2.3~alpha2") }
    end
  end
end
