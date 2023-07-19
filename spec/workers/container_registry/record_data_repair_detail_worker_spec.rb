# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::RecordDataRepairDetailWorker, :aggregate_failures, :clean_gitlab_redis_shared_state,
  feature_category: :container_registry do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    context 'with no work to do - no projects pending analysis' do
      it 'will not try to get an exclusive lease and connect to the endpoint' do
        allow(Project).to receive(:pending_data_repair_analysis).and_return([])
        expect(::Gitlab::ExclusiveLease).not_to receive(:new)

        expect(::ContainerRegistry::GitlabApiClient).not_to receive(:each_sub_repositories_with_tag_page)

        perform_work
      end
    end

    context 'with work to do' do
      let_it_be(:path) { 'build/cng/docker-alpine' }
      let_it_be(:group) { create(:group, path: 'build') }
      let_it_be(:project) { create(:project, name: 'cng', namespace: group) }

      let_it_be(:container_repository) { create(:container_repository, project: project, name: "docker-alpine") }
      let_it_be(:lease_key) { "container_registry_data_repair_detail_worker:#{project.id}" }

      before do
        allow(ContainerRegistry::GitlabApiClient).to receive(:each_sub_repositories_with_tag_page)
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
      end

      context 'when on Gitlab.com', :saas do
        before do
          allow(::Gitlab).to receive(:com_except_jh?).and_return(true)
        end

        it 'obtains exclusive lease on the project' do
          pending_analysis = Project.pending_data_repair_analysis
          limited_pending_analysis = Project.pending_data_repair_analysis
          expect(pending_analysis).to receive(:limit).and_return(limited_pending_analysis)
          expect(limited_pending_analysis).to receive(:sample).and_call_original

          expect(Project).to receive(:pending_data_repair_analysis).and_return(pending_analysis)
          expect_to_obtain_exclusive_lease("container_registry_data_repair_detail_worker:#{project.id}",
            timeout: described_class::LEASE_TIMEOUT)
          expect_to_cancel_exclusive_lease("container_registry_data_repair_detail_worker:#{project.id}", 'uuid')

          perform_work
        end

        it 'queries how many are existing repositories and counts the missing ones' do
          stub_exclusive_lease("container_registry_data_repair_detail_worker:#{project.id}",
            timeout: described_class::LEASE_TIMEOUT)
          allow(ContainerRegistry::GitlabApiClient).to receive(:each_sub_repositories_with_tag_page)
            .with(path: project.full_path, page_size: 50).and_yield(
              [
                { "path" => container_repository.path },
                { "path" => 'missing1/repository' },
                { "path" => 'missing2/repository' }
              ]
            )

          expect(worker).not_to receive(:log_extra_metadata_on_done)
          expect { perform_work }.to change { ContainerRegistry::DataRepairDetail.count }.from(0).to(1)
          expect(ContainerRegistry::DataRepairDetail.first).to have_attributes(project: project, missing_count: 2)
        end

        it 'logs invalid paths' do
          stub_exclusive_lease("container_registry_data_repair_detail_worker:#{project.id}",
            timeout: described_class::LEASE_TIMEOUT)
          valid_path = ContainerRegistry::Path.new('valid/path')
          invalid_path = ContainerRegistry::Path.new('invalid/path')
          allow(valid_path).to receive(:valid?).and_return(true)
          allow(invalid_path).to receive(:valid?).and_return(false)

          allow(ContainerRegistry::GitlabApiClient).to receive(:each_sub_repositories_with_tag_page)
            .with(path: project.full_path, page_size: 50).and_yield(
              [
                { "path" => valid_path.to_s },
                { "path" => invalid_path.to_s }
              ]
            )

          allow(ContainerRegistry::Path).to receive(:new).with(valid_path.to_s).and_return(valid_path)
          allow(ContainerRegistry::Path).to receive(:new).with(invalid_path.to_s).and_return(invalid_path)

          expect(worker).to receive(:log_extra_metadata_on_done).with(
            :invalid_paths_parsed_in_container_repository_repair,
            "invalid/path"
          )
          perform_work
        end

        it_behaves_like 'an idempotent worker' do
          it 'creates a data repair detail' do
            expect { perform_work }.to change { ContainerRegistry::DataRepairDetail.count }.from(0).to(1)
            expect(project.container_registry_data_repair_detail).to be_present
          end
        end

        context 'when the lease cannot be obtained' do
          before do
            stub_exclusive_lease_taken(lease_key, timeout: described_class::LEASE_TIMEOUT)
          end

          it 'logs an error and does not proceed' do
            expect(worker).to receive(:log_lease_taken)
            expect(ContainerRegistry::GitlabApiClient).not_to receive(:each_sub_repositories_with_tag_page)

            perform_work
          end

          it 'does not create the data repair detail' do
            perform_work

            expect(project.reload.container_registry_data_repair_detail).to be_nil
          end
        end

        context 'when an error occurs' do
          before do
            stub_exclusive_lease("container_registry_data_repair_detail_worker:#{project.id}",
              timeout: described_class::LEASE_TIMEOUT)
            allow(ContainerRegistry::GitlabApiClient).to receive(:each_sub_repositories_with_tag_page)
              .with(path: project.full_path, page_size: 50).and_raise(RuntimeError)
          end

          it 'logs the error' do
            expect(::Gitlab::ErrorTracking).to receive(:log_exception)
              .with(instance_of(RuntimeError), class: described_class.name)

            perform_work
          end

          it 'sets the status of the repair detail to failed' do
            expect { perform_work }.to change { ContainerRegistry::DataRepairDetail.failed.count }.from(0).to(1)
            expect(project.reload.container_registry_data_repair_detail.failed?).to eq(true)
          end
        end
      end

      context 'when not on Gitlab.com' do
        it 'will not do anything' do
          expect(::Gitlab::ExclusiveLease).not_to receive(:new)
          expect(::ContainerRegistry::GitlabApiClient).not_to receive(:each_sub_repositories_with_tag_page)

          perform_work
        end
      end
    end
  end

  describe '#max_running_jobs' do
    let(:max_concurrency) { 3 }

    before do
      stub_application_setting(
        container_registry_data_repair_detail_worker_max_concurrency: max_concurrency
      )
    end

    subject { worker.max_running_jobs }

    it { is_expected.to eq(max_concurrency) }
  end

  describe '#remaining_work_count' do
    let_it_be(:max_running_jobs) { 5 }
    let_it_be(:pending_projects) do
      create_list(:project, max_running_jobs + 2)
    end

    subject { worker.remaining_work_count }

    context 'when on Gitlab.com', :saas do
      before do
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
        allow(worker).to receive(:max_running_jobs).and_return(max_running_jobs)
      end

      it { is_expected.to eq(worker.max_running_jobs + 1) }

      context 'when the Gitlab API is not supported' do
        before do
          allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
        end

        it { is_expected.to eq(0) }
      end
    end

    context 'when not on Gitlab.com' do
      it { is_expected.to eq(0) }
    end

    context 'when registry_data_repair_worker feature is disabled' do
      before do
        stub_feature_flags(registry_data_repair_worker: false)
      end

      it { is_expected.to eq(0) }
    end
  end
end
