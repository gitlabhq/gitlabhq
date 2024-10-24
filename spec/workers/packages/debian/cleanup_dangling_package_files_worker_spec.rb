# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::CleanupDanglingPackageFilesWorker, type: :worker, feature_category: :package_registry do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has :until_executed deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform' do
    let_it_be_with_reload(:distribution) { create(:debian_project_distribution, :with_file, codename: 'unstable') }
    let_it_be(:incoming) { create(:debian_incoming, project: distribution.project) }
    let_it_be(:package) { create(:debian_package, project: distribution.project) }

    subject { described_class.new.perform }

    context 'when debian_packages flag is disabled' do
      before do
        stub_feature_flags(debian_packages: false)
      end

      it 'does nothing' do
        expect(::Packages::MarkPackageFilesForDestructionService).not_to receive(:new)

        subject
      end
    end

    context 'with mocked service returning success' do
      it 'calls MarkPackageFilesForDestructionService' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect_next_instance_of(::Packages::MarkPackageFilesForDestructionService) do |service|
          expect(service).to receive(:execute)
            .with(batch_deadline: an_instance_of(ActiveSupport::TimeWithZone))
            .and_return(ServiceResponse.success)
        end

        subject
      end
    end

    context 'with mocked service returning error' do
      it 'ignore error' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
        expect_next_instance_of(::Packages::MarkPackageFilesForDestructionService) do |service|
          expect(service).to receive(:execute)
            .with(batch_deadline: an_instance_of(ActiveSupport::TimeWithZone))
            .and_return(ServiceResponse.error(message: 'Custom error'))
        end

        subject
      end
    end

    context 'when the service raises an error' do
      it 'logs exception' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(ArgumentError)
        )
        expect_next_instance_of(::Packages::MarkPackageFilesForDestructionService) do |service|
          expect(service).to receive(:execute)
            .and_raise(ArgumentError, 'foobar')
        end

        subject
      end
    end

    context 'with valid parameters' do
      it_behaves_like 'an idempotent worker' do
        before do
          incoming.package_files.first.debian_file_metadatum.update! updated_at: 1.day.ago
          incoming.package_files.second.update! updated_at: 1.day.ago, status: :error
        end

        it 'mark dangling package files as pending destruction', :aggregate_failures do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          # Using subject inside this block will process the job multiple times
          expect { subject }
            .to not_change { distribution.project.package_files.count }
            .and change { distribution.project.package_files.pending_destruction.count }.from(0).to(1)
            .and not_change { distribution.project.packages.count }
        end
      end
    end
  end
end
