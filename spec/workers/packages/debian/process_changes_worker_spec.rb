# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ProcessChangesWorker, type: :worker do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, codename: 'unstable') }

  let(:incoming) { create(:debian_incoming, project: distribution.project) }
  let(:package_file) { incoming.package_files.last }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:package_file_id) { package_file.id }
    let(:user_id) { user.id }

    subject { worker.perform(package_file_id, user_id) }

    context 'with mocked service' do
      it 'calls ProcessChangesService' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect_next_instance_of(::Packages::Debian::ProcessChangesService) do |service|
          expect(service).to receive(:execute)
            .with(no_args)
        end

        subject
      end
    end

    context 'with non existing package file' do
      let(:package_file_id) { non_existing_record_id }

      it 'returns early without error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect(::Packages::Debian::ProcessChangesService).not_to receive(:new)

        subject
      end
    end

    context 'with nil package file id' do
      let(:package_file_id) { nil }

      it 'returns early without error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect(::Packages::Debian::ProcessChangesService).not_to receive(:new)

        subject
      end
    end

    context 'with non existing user' do
      let(:user_id) { non_existing_record_id }

      it 'returns early without error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect(::Packages::Debian::ProcessChangesService).not_to receive(:new)

        subject
      end
    end

    context 'with nil user id' do
      let(:user_id) { nil }

      it 'returns early without error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect(::Packages::Debian::ProcessChangesService).not_to receive(:new)

        subject
      end
    end

    context 'when the service raises an error' do
      let(:package_file) { incoming.package_files.first }

      it 'removes package file', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Packages::Debian::ExtractChangesMetadataService::ExtractionError),
          package_file_id: package_file_id,
          user_id: user_id
        )
        expect { subject }
          .to not_change { Packages::Package.count }
          .and change { Packages::PackageFile.count }.by(-1)
          .and change { incoming.package_files.count }.from(7).to(6)

        expect { package_file.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [package_file.id, user.id] }

      it 'sets the Debian file type as changes', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        # Using subject inside this block will process the job multiple times
        expect { subject }
          .to change { Packages::Package.count }.from(1).to(2)
          .and not_change { Packages::PackageFile.count }
          .and change { incoming.package_files.count }.from(7).to(0)
          .and change { package_file&.debian_file_metadatum&.reload&.file_type }.from('unknown').to('changes')

        created_package = Packages::Package.last
        expect(created_package.name).to eq 'sample'
        expect(created_package.version).to eq '1.2.3~alpha2'
        expect(created_package.creator).to eq user
      end
    end
  end
end
