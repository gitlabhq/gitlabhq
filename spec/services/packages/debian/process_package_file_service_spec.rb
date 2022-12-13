# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, codename: 'unstable') }

    let!(:incoming) { create(:debian_incoming, project: distribution.project) }

    let(:distribution_name) { distribution.codename }
    let(:debian_file_metadatum) { package_file.debian_file_metadatum }

    subject { described_class.new(package_file, user, distribution_name, component_name) }

    RSpec.shared_context 'with Debian package file' do |file_name|
      let(:package_file) { incoming.package_files.with_file_name(file_name).first }
    end

    using RSpec::Parameterized::TableSyntax

    where(:case_name, :expected_file_type, :file_name, :component_name) do
      'with a deb'   | 'deb'  | 'libsample0_1.2.3~alpha2_amd64.deb'   | 'main'
      'with an udeb' | 'udeb' | 'sample-udeb_1.2.3~alpha2_amd64.udeb' | 'contrib'
    end

    with_them do
      include_context 'with Debian package file', params[:file_name] do
        it 'creates package and updates package file', :aggregate_failures do
          expect(::Packages::Debian::GenerateDistributionWorker)
            .to receive(:perform_async).with(:project, distribution.id)
          expect { subject.execute }
            .to change(Packages::Package, :count).from(1).to(2)
            .and not_change(Packages::PackageFile, :count)
            .and change(incoming.package_files, :count).from(7).to(6)
            .and change(debian_file_metadatum, :file_type).from('unknown').to(expected_file_type)
            .and change(debian_file_metadatum, :component).from(nil).to(component_name)

          created_package = Packages::Package.last
          expect(created_package.name).to eq 'sample'
          expect(created_package.version).to eq '1.2.3~alpha2'
          expect(created_package.creator).to eq user
        end

        context 'with existing package' do
          let_it_be_with_reload(:existing_package) do
            create(:debian_package, name: 'sample', version: '1.2.3~alpha2', project: distribution.project)
          end

          before do
            existing_package.update!(debian_distribution: distribution)
          end

          it 'does not create a package and assigns the package_file to the existing package' do
            expect(::Packages::Debian::GenerateDistributionWorker)
              .to receive(:perform_async).with(:project, distribution.id)
            expect { subject.execute }
              .to not_change(Packages::Package, :count)
              .and not_change(Packages::PackageFile, :count)
              .and change(incoming.package_files, :count).from(7).to(6)
              .and change(package_file, :package).from(incoming).to(existing_package)
              .and change(debian_file_metadatum, :file_type).from('unknown').to(expected_file_type.to_s)
              .and change(debian_file_metadatum, :component).from(nil).to(component_name)
          end

          context 'when marked as pending_destruction' do
            it 'does not re-use the existing package' do
              existing_package.pending_destruction!

              expect { subject.execute }
                .to change(Packages::Package, :count).by(1)
                .and not_change(Packages::PackageFile, :count)
            end
          end
        end
      end
    end

    context 'without a distribution' do
      let(:package_file) { incoming.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:component_name) { 'main' }

      before do
        distribution.destroy!
      end

      it 'raise ActiveRecord::RecordNotFound', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(incoming.package_files, :count)
          .and raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with package file without Debian metadata' do
      let!(:package_file) { create(:debian_package_file, without_loaded_metadatum: true) }
      let(:component_name) { 'main' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(incoming.package_files, :count)
          .and raise_error(ArgumentError, 'package file without Debian metadata')
      end
    end

    context 'with already processed package file' do
      let_it_be(:package_file) { create(:debian_package_file) }

      let(:component_name) { 'main' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(incoming.package_files, :count)
          .and raise_error(ArgumentError, 'already processed package file')
      end
    end

    context 'with invalid package file type' do
      let(:package_file) { incoming.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }
      let(:component_name) { 'main' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(incoming.package_files, :count)
          .and raise_error(ArgumentError, 'invalid package file type: source')
      end
    end

    context 'when creating package fails' do
      let(:package_file) { incoming.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:component_name) { 'main' }

      before do
        allow_next_instance_of(::Packages::Debian::FindOrCreatePackageService) do |find_or_create_package_service|
          allow(find_or_create_package_service)
            .to receive(:execute).and_raise(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
        end
      end

      it 're-raise error', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(incoming.package_files, :count)
          .and raise_error(ActiveRecord::ConnectionTimeoutError, 'connect timeout')
      end
    end
  end
end
