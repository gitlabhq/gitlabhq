# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileService, feature_category: :package_registry do
  describe '#execute' do
    let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_suite, :with_file) }

    let!(:package) { create(:debian_package, :processing, project: distribution.project, published_in: nil) }
    let(:distribution_name) { distribution.codename }
    let(:component_name) { 'main' }
    let(:debian_file_metadatum) { package_file.debian_file_metadatum }

    subject { described_class.new(package_file, distribution_name, component_name) }

    shared_examples 'updates package and package file' do
      it 'updates package and package file', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker)
          .to receive(:perform_async).with(:project, distribution.id)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and change { Packages::Debian::Publication.count }.by(1)
          .and not_change(package.package_files, :count)
          .and change { package.reload.name }.to('sample')
          .and change { package.reload.version }.to('1.2.3~alpha2')
          .and change { package.reload.status }.from('processing').to('default')
          .and change { package.reload.debian_publication }.from(nil)
          .and change { debian_file_metadatum.file_type }.from('unknown').to(expected_file_type)
          .and change { debian_file_metadatum.component }.from(nil).to(component_name)
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:case_name, :expected_file_type, :file_name, :component_name) do
      'with a deb'   | 'deb'  | 'libsample0_1.2.3~alpha2_amd64.deb'   | 'main'
      'with an udeb' | 'udeb' | 'sample-udeb_1.2.3~alpha2_amd64.udeb' | 'contrib'
      'with an ddeb' | 'ddeb' | 'sample-ddeb_1.2.3~alpha2_amd64.ddeb' | 'main'
    end

    with_them do
      context 'with Debian package file' do
        let(:package_file) { package.package_files.with_file_name(file_name).first }

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
            expect { subject.execute }
              .to change { Packages::Package.count }.from(2).to(1)
              .and change { Packages::PackageFile.count }.from(16).to(9)
              .and not_change(Packages::Debian::Publication, :count)
              .and change { package.package_files.count }.from(8).to(0)
              .and change { package_file.package }.from(package).to(matching_package)
              .and not_change(matching_package, :name)
              .and not_change(matching_package, :version)
              .and change { debian_file_metadatum.file_type }.from('unknown').to(expected_file_type)
              .and change { debian_file_metadatum.component }.from(nil).to(component_name)

            expect { package.reload }
              .to raise_error(ActiveRecord::RecordNotFound)
          end
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

          it 'raise ArgumentError', :aggregate_failures do
            expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
            expect { subject.execute }
              .to not_change(Packages::Package, :count)
              .and not_change(Packages::PackageFile, :count)
              .and not_change(package.package_files, :count)
              .and raise_error(ArgumentError, "Debian package sample 1.2.3~alpha2 exists " \
                                              "in distribution #{matching_package.debian_distribution.codename}")
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

    context 'without a distribution' do
      let(:package_file) { package.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
      let(:component_name) { 'main' }

      before do
        distribution.destroy!
      end

      it 'raise ActiveRecord::RecordNotFound', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(package.package_files, :count)
          .and raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without distribution name' do
      let!(:package_file) { create(:debian_package_file, without_loaded_metadatum: true) }
      let(:distribution_name) { '' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(package.package_files, :count)
          .and raise_error(ArgumentError, 'missing distribution name')
      end
    end

    context 'without component name' do
      let!(:package_file) { create(:debian_package_file, without_loaded_metadatum: true) }
      let(:component_name) { '' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(package.package_files, :count)
          .and raise_error(ArgumentError, 'missing component name')
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
          .and not_change(package.package_files, :count)
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
          .and not_change(package.package_files, :count)
          .and raise_error(ArgumentError, 'already processed package file')
      end
    end

    context 'with invalid package file type' do
      let(:package_file) { package.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }
      let(:component_name) { 'main' }

      it 'raise ArgumentError', :aggregate_failures do
        expect(::Packages::Debian::GenerateDistributionWorker).not_to receive(:perform_async)
        expect { subject.execute }
          .to not_change(Packages::Package, :count)
          .and not_change(Packages::PackageFile, :count)
          .and not_change(package.package_files, :count)
          .and raise_error(ArgumentError, 'invalid package file type: source')
      end
    end
  end
end
