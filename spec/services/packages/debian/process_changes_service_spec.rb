# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ProcessChangesService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, codename: 'unstable') }
    let_it_be(:incoming) { create(:debian_incoming, project: distribution.project) }

    let(:package_file) { incoming.package_files.last }

    subject { described_class.new(package_file, user) }

    context 'with valid package file' do
      it 'updates package and package file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).to receive(:perform_async).with(:project, distribution.id)
        expect { subject.execute }
          .to change { Packages::Package.count }.from(1).to(2)
          .and not_change { Packages::PackageFile.count }
          .and change { incoming.package_files.count }.from(7).to(0)
          .and change { package_file.debian_file_metadatum&.reload&.file_type }.from('unknown').to('changes')

        created_package = Packages::Package.last
        expect(created_package.name).to eq 'sample'
        expect(created_package.version).to eq '1.2.3~alpha2'
        expect(created_package.creator).to eq user
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
          .and not_change { distribution.reload.needs_update? }
          .and raise_error(Packages::Debian::ExtractChangesMetadataService::ExtractionError, 'is not a changes file')
      end
    end

    context 'when creating package fails' do
      before do
        allow_next_instance_of(::Packages::Debian::FindOrCreatePackageService) do |find_or_create_package_service|
          expect(find_or_create_package_service).to receive(:execute).and_raise(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
        end
      end

      it 'remove the package file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { incoming.package_files.count }
          .and not_change { distribution.reload.needs_update? }
          .and raise_error(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
      end
    end
  end
end
