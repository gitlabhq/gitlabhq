# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cleanup::ExecutePolicyWorker, feature_category: :package_registry do
  let(:worker) { described_class.new }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has :none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    shared_examples 'not executing any policy' do
      it 'is a no op' do
        expect(::Packages::Cleanup::ExecutePolicyService).not_to receive(:new)

        expect { perform_work }.not_to change { Packages::PackageFile.installable.count }
      end
    end

    context 'with no policies' do
      it_behaves_like 'not executing any policy'
    end

    context 'with no runnable policies' do
      let_it_be(:policy) { create(:packages_cleanup_policy) }

      it_behaves_like 'not executing any policy'
    end

    context 'with runnable policies linked to no packages' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable) }

      it_behaves_like 'not executing any policy'
    end

    context 'with runnable policies linked to packages' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable, keep_n_duplicated_package_files: '1') }
      let_it_be(:package) { create(:generic_package, project: policy.project) }

      let_it_be(:package_file1) { create(:package_file, file_name: 'test1', package: package) }
      let_it_be(:package_file2) { create(:package_file, file_name: 'test1', package: package) }

      it_behaves_like 'an idempotent worker' do
        it 'executes the policy' do
          expect(::Packages::Cleanup::ExecutePolicyService)
            .to receive(:new).with(policy).and_call_original
          expect_log_extra_metadata(:project_id, policy.project_id)
          expect_log_extra_metadata(:execution_timeout, false)
          expect_log_extra_metadata(:marked_package_files_total_count, 1)
          expect_log_extra_metadata(:unique_package_id_and_file_name_total_count, 1)

          expect { perform_work }
            .to change { package.package_files.installable.count }.by(-1)
            .and change { policy.reload.next_run_at.future? }.from(false).to(true)
        end

        context 'with a timeout' do
          let(:mark_service_response) do
            ServiceResponse.error(
              message: 'Timeout',
              payload: { marked_package_files_count: 1 }
            )
          end

          it 'executes the policy partially' do
            expect_next_instance_of(::Packages::MarkPackageFilesForDestructionService) do |service|
              expect(service).to receive(:execute).and_return(mark_service_response)
            end

            expect_log_extra_metadata(:project_id, policy.project_id)
            expect_log_extra_metadata(:execution_timeout, true)
            expect_log_extra_metadata(:marked_package_files_total_count, 1)
            expect_log_extra_metadata(:unique_package_id_and_file_name_total_count, 1)

            expect { perform_work }
              .to change { policy.reload.next_run_at.future? }.from(false).to(true)
          end
        end
      end

      context 'with several eligible policies' do
        let_it_be(:policy2) { create(:packages_cleanup_policy, :runnable) }
        let_it_be(:package2) { create(:generic_package, project: policy2.project) }

        before do
          policy2.update_column(:next_run_at, 100.years.ago)
        end

        it 'executes the most urgent policy' do
          expect(::Packages::Cleanup::ExecutePolicyService)
            .to receive(:new).with(policy2).and_call_original
          expect_log_extra_metadata(:project_id, policy2.project_id)
          expect_log_extra_metadata(:execution_timeout, false)
          expect_log_extra_metadata(:marked_package_files_total_count, 0)
          expect_log_extra_metadata(:unique_package_id_and_file_name_total_count, 0)

          expect { perform_work }
            .to change { policy2.reload.next_run_at.future? }.from(false).to(true)
            .and not_change { policy.reload.next_run_at }
        end
      end
    end

    context 'with runnable policy linked to packages in a disabled state' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable, keep_n_duplicated_package_files: 'all') }
      let_it_be(:package) { create(:generic_package, project: policy.project) }

      it_behaves_like 'not executing any policy'
    end

    def expect_log_extra_metadata(key, value)
      expect(worker).to receive(:log_extra_metadata_on_done).with(key, value)
    end
  end

  describe '#remaining_work_count' do
    subject { worker.remaining_work_count }

    context 'with no policies' do
      it { is_expected.to eq(0) }
    end

    context 'with no runnable policies' do
      let_it_be(:policy) { create(:packages_cleanup_policy) }

      it { is_expected.to eq(0) }
    end

    context 'with runnable policies linked to no packages' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable) }

      it { is_expected.to eq(0) }
    end

    context 'with runnable policies linked to packages' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable) }
      let_it_be(:package) { create(:generic_package, project: policy.project) }

      it { is_expected.to eq(1) }
    end

    context 'with runnable policy linked to packages in a disabled state' do
      let_it_be(:policy) { create(:packages_cleanup_policy, :runnable, keep_n_duplicated_package_files: 'all') }
      let_it_be(:package) { create(:generic_package, project: policy.project) }

      it { is_expected.to eq(0) }
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { 50 }

    subject { worker.max_running_jobs }

    before do
      stub_application_setting(package_registry_cleanup_policies_worker_capacity: capacity)
    end

    it { is_expected.to eq(capacity) }
  end
end
