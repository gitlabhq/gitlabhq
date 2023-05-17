# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessChangesService, feature_category: :package_registry do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, suite: 'unstable') }

    let!(:incoming) { create(:debian_incoming, project: distribution.project) }

    let(:package_file) { incoming.package_files.with_file_name('sample_1.2.3~alpha2_amd64.changes').first }

    subject { described_class.new(package_file, user) }

    context 'with valid package file' do
      it 'updates package and package file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).to receive(:perform_async).with(:project, distribution.id)
        expect { subject.execute }
          .to change { Packages::Package.count }.from(1).to(2)
          .and not_change { Packages::PackageFile.count }
          .and change { incoming.package_files.count }.from(8).to(0)
          .and change { package_file.debian_file_metadatum&.reload&.file_type }.from('unknown').to('changes')

        created_package = Packages::Package.last
        expect(created_package.name).to eq 'sample'
        expect(created_package.version).to eq '1.2.3~alpha2'
        expect(created_package.creator).to eq user
      end

      context 'with non-matching distribution' do
        before do
          distribution.update! suite: FFaker::Lorem.word
        end

        it { expect { subject.execute }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'with missing field in .changes file' do
        shared_examples 'raises error with missing field' do |missing_field|
          before do
            allow_next_instance_of(::Packages::Debian::ExtractChangesMetadataService) do |extract_changes_metadata_service|
              expect(extract_changes_metadata_service).to receive(:execute).once.and_wrap_original do |m, *args|
                metadata = m.call(*args)
                metadata[:fields].delete(missing_field)
                metadata
              end
            end
          end

          it { expect { subject.execute }.to raise_error(ArgumentError, "missing #{missing_field} field") }
        end

        it_behaves_like 'raises error with missing field', 'Source'
        it_behaves_like 'raises error with missing field', 'Version'
        it_behaves_like 'raises error with missing field', 'Distribution'
      end

      context 'with existing package in the same distribution' do
        let_it_be_with_reload(:existing_package) do
          create(:debian_package, name: 'sample', version: '1.2.3~alpha2', project: distribution.project, published_in: distribution)
        end

        it 'does not create a package and assigns the package_file to the existing package' do
          expect { subject.execute }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::PackageFile.count }
            .and change { package_file.package }.to(existing_package)
        end

        context 'and marked as pending_destruction' do
          it 'does not re-use the existing package' do
            existing_package.pending_destruction!

            expect { subject.execute }
              .to change { Packages::Package.count }.by(1)
              .and not_change { Packages::PackageFile.count }
          end
        end
      end

      context 'with existing package in another distribution' do
        let_it_be_with_reload(:existing_package) do
          create(:debian_package, name: 'sample', version: '1.2.3~alpha2', project: distribution.project)
        end

        it 'raise ExtractionError' do
          expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
          expect { subject.execute }
            .to not_change { Packages::Package.count }
            .and not_change { Packages::PackageFile.count }
            .and not_change { incoming.package_files.count }
            .and raise_error(ArgumentError,
              "Debian package #{existing_package.name} #{existing_package.version} exists " \
              "in distribution #{existing_package.debian_distribution.codename}")
        end

        context 'and marked as pending_destruction' do
          it 'does not re-use the existing package' do
            existing_package.pending_destruction!

            expect { subject.execute }
              .to change { Packages::Package.count }.by(1)
              .and not_change { Packages::PackageFile.count }
          end
        end
      end
    end

    context 'with invalid package file' do
      let(:package_file) { incoming.package_files.first }

      it 'raise ExtractionError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { incoming.package_files.count }
          .and raise_error(Packages::Debian::ExtractChangesMetadataService::ExtractionError, 'is not a changes file')
      end
    end

    context 'when creating package fails' do
      before do
        allow_next_instance_of(::Packages::Debian::FindOrCreatePackageService) do |find_or_create_package_service|
          expect(find_or_create_package_service).to receive(:execute).and_raise(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
        end
      end

      it 're-raise error', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { incoming.package_files.count }
          .and raise_error(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
      end
    end
  end
end
