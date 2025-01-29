# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackageFilesForDestructionWorker, :aggregate_failures, feature_category: :package_registry do
  describe '#perform' do
    let_it_be(:package) { create(:generic_package) }
    let_it_be(:package_files) { create_list(:package_file, 3, package: package) }

    let(:worker) { described_class.new }
    let(:job_args) { [package.id] }

    subject { worker.perform(*job_args) }

    context 'with a valid package id' do
      it_behaves_like 'an idempotent worker'

      it 'marks all package files as pending_destruction' do
        package_files_count = package.package_files.count

        expect(package.package_files.pending_destruction.count).to eq(0)
        expect(package.package_files.default.count).to eq(package_files_count)

        subject

        expect(package.package_files.default.count).to eq(0)
        expect(package.package_files.pending_destruction.count).to eq(package_files_count)
      end
    end

    context 'with an invalid package id' do
      let(:job_args) { [non_existing_record_id] }

      it_behaves_like 'an idempotent worker'

      it 'marks no packag files' do
        expect(::Packages::MarkPackageFilesForDestructionService).not_to receive(:new)

        expect { subject }.not_to change { ::Packages::PackageFile.pending_destruction.count }
      end
    end

    context 'with a nil package id' do
      let(:job_args) { [nil] }

      it_behaves_like 'an idempotent worker'

      it 'marks no packag files' do
        expect(::Packages::MarkPackageFilesForDestructionService).not_to receive(:new)

        expect { subject }.not_to change { ::Packages::PackageFile.pending_destruction.count }
      end
    end
  end
end
