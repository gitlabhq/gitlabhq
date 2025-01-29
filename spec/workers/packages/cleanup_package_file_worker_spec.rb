# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::CleanupPackageFileWorker, type: :worker, feature_category: :package_registry do
  let_it_be_with_reload(:package) { create(:generic_package) }

  let(:worker) { described_class.new }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has :none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

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
        expect { package_file2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with a duplicated PyPI package file' do
        let_it_be_with_reload(:duplicated_package_file) { create(:package_file, package: package) }

        before do
          package.update!(package_type: :pypi, version: '1.2.3')
          duplicated_package_file.update_column(:file_name, package_file2.file_name)
        end

        it 'deletes one of the duplicates' do
          expect { subject }.to change { Packages::PackageFile.count }.by(-1)
                                  .and not_change { Packages::Package.count }
          expect { package_file2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with a package file to destroy' do
      let_it_be(:package_file) { create(:package_file, :pending_destruction) }

      context 'with an error during the destroy' do
        before do
          allow(worker).to receive(:log_metadata).and_raise('Error!')
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(RuntimeError), class: described_class.name)
          expect { subject }.to change { Packages::PackageFile.error.count }.from(0).to(1)
          expect(package_file.reload).to be_error
        end
      end

      context 'when trying to destroy a destroyed record' do
        before do
          allow_next_found_instance_of(Packages::PackageFile) do |package_file|
            destroy_method = package_file.method(:destroy!)

            allow(package_file).to receive(:destroy!) do
              destroy_method.call

              raise 'Error!'
            end
          end
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(RuntimeError), class: described_class.name)
          expect { subject }.not_to change { Packages::PackageFile.count }
          expect(package_file.reload).to be_error
        end
      end
    end

    describe 'removing the last package file' do
      let_it_be(:package_file) { create(:package_file, :pending_destruction, package: package) }

      it 'deletes the package file and the package' do
        expect(worker).to receive(:log_extra_metadata_on_done).twice

        expect { subject }.to change { Packages::PackageFile.count }.by(-1)
          .and change { Packages::Package.count }.by(-1)
      end
    end

    describe 'removing the last package file in an ML model package' do
      let_it_be_with_reload(:package) { create(:ml_model_package) }
      let_it_be(:package_file) { create(:package_file, :pending_destruction, package: package) }

      it 'deletes the package file but keeps the package' do
        expect(worker).to receive(:log_extra_metadata_on_done).twice

        expect { subject }.to change { Packages::PackageFile.count }.by(-1)
          .and change { Packages::Package.count }.by(0)
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
    before_all do
      create_list(:package_file, 2, :pending_destruction, package: package)
    end

    subject { worker.remaining_work_count }

    it { is_expected.to eq(2) }
  end
end
