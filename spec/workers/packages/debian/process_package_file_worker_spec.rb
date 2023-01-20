# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, codename: 'unstable') }

  let(:incoming) { create(:debian_incoming, project: distribution.project) }
  let(:distribution_name) { distribution.codename }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:package_file_id) { package_file.id }
    let(:user_id) { user.id }

    subject { worker.perform(package_file_id, user_id, distribution_name, component_name) }

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
    end

    with_them do
      context 'with Debian package file' do
        let(:package_file) { incoming.package_files.with_file_name(file_name).first }

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

        context 'with non existing user' do
          let(:user_id) { non_existing_record_id }

          it_behaves_like 'returns early without error'
        end

        context 'with nil user id' do
          let(:user_id) { nil }

          it_behaves_like 'returns early without error'
        end

        context 'when the service raises an error' do
          let(:package_file) { incoming.package_files.with_file_name('sample_1.2.3~alpha2.tar.xz').first }

          it 'removes package file', :aggregate_failures do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              instance_of(ArgumentError),
              package_file_id: package_file_id,
              user_id: user_id,
              distribution_name: distribution_name,
              component_name: component_name
            )
            expect { subject }
              .to not_change(Packages::Package, :count)
              .and change { Packages::PackageFile.count }.by(-1)
              .and change { incoming.package_files.count }.from(7).to(6)

            expect { package_file.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        it_behaves_like 'an idempotent worker' do
          let(:job_args) { [package_file.id, user.id, distribution_name, component_name] }

          it 'sets the Debian file type as deb', :aggregate_failures do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

            # Using subject inside this block will process the job multiple times
            expect { subject }
              .to change { Packages::Package.count }.from(1).to(2)
              .and not_change(Packages::PackageFile, :count)
              .and change { incoming.package_files.count }.from(7).to(6)
              .and change {
                     package_file&.debian_file_metadatum&.reload&.file_type
                   }.from('unknown').to(expected_file_type)

            created_package = Packages::Package.last
            expect(created_package.name).to eq 'sample'
            expect(created_package.version).to eq '1.2.3~alpha2'
            expect(created_package.creator).to eq user
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
      let(:package_file) { incoming.package_files.with_file_name('libsample0_1.2.3~alpha2_amd64.deb').first }
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
