# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::CleanupPackageFileWorker do
  let_it_be(:package) { create(:package) }

  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject { worker.perform_work }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:package_file1) { create(:package_file, package: package) }
      let_it_be(:package_file2) { create(:package_file, :pending_destruction, package: package) }
      let_it_be(:package_file3) { create(:package_file, :pending_destruction, package: package, updated_at: 1.year.ago, created_at: 1.year.ago) }

      it 'deletes the oldest package file pending destruction based on id', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).twice

        expect { subject }.to change { Packages::PackageFile.count }.by(-1)
          .and not_change { Packages::Package.count }
      end
    end

    context 'with an error during the destroy' do
      let_it_be(:package_file) { create(:package_file, :pending_destruction) }

      before do
        expect(worker).to receive(:log_metadata).and_raise('Error!')
      end

      it 'handles the error' do
        expect { subject }.to change { Packages::PackageFile.error.count }.from(0).to(1)
        expect(package_file.reload).to be_error
      end
    end

    context 'removing the last package file' do
      let_it_be(:package_file) { create(:package_file, :pending_destruction, package: package) }

      it 'deletes the package file and the package' do
        expect(worker).to receive(:log_extra_metadata_on_done).twice

        expect { subject }.to change { Packages::PackageFile.count }.by(-1)
          .and change { Packages::Package.count }.by(-1)
      end
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { 5 }

    subject { worker.max_running_jobs }

    before do
      stub_application_setting(packages_cleanup_package_file_worker_capacity: capacity)
    end

    it { is_expected.to eq(capacity) }
  end

  describe '#remaining_work_count' do
    before(:context) do
      create_list(:package_file, 3, :pending_destruction, package: package)
    end

    subject { worker.remaining_work_count }

    it { is_expected.to eq(3) }
  end
end
