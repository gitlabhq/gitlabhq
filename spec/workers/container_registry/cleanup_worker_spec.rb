# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::CleanupWorker, :aggregate_failures, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be_with_reload(:container_repository) { create(:container_repository) }

    subject(:perform) { worker.perform }

    context 'with no delete scheduled container repositories' do
      it "doesn't enqueue delete container repository jobs" do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).not_to receive(:perform_with_capacity)

        perform
      end
    end

    context 'with delete scheduled container repositories' do
      before do
        container_repository.delete_scheduled!
      end

      it 'enqueues delete container repository jobs' do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).to receive(:perform_with_capacity)

        perform
      end
    end

    context 'with stale delete ongoing container repositories' do
      let(:delete_started_at) { (described_class::STALE_DELETE_THRESHOLD + 5.minutes).ago }

      before do
        container_repository.update!(status: :delete_ongoing, delete_started_at: delete_started_at)
      end

      it 'resets them and enqueue delete container repository jobs' do
        expect(ContainerRegistry::DeleteContainerRepositoryWorker).to receive(:perform_with_capacity)

        expect { perform }
          .to change { container_repository.reload.status }.from('delete_ongoing').to('delete_scheduled')
                .and change { container_repository.reload.delete_started_at }.to(nil)
      end
    end

    context 'with stale ongoing repair details' do
      let_it_be(:stale_updated_at) { (described_class::STALE_REPAIR_DETAIL_THRESHOLD + 5.minutes).ago }
      let_it_be(:recent_updated_at) { (described_class::STALE_REPAIR_DETAIL_THRESHOLD - 5.minutes).ago }
      let_it_be(:old_repair_detail) { create(:container_registry_data_repair_detail, updated_at: stale_updated_at) }
      let_it_be(:new_repair_detail) { create(:container_registry_data_repair_detail, updated_at: recent_updated_at) }

      it 'deletes them' do
        expect { perform }.to change { ContainerRegistry::DataRepairDetail.count }.from(2).to(1)
        expect(ContainerRegistry::DataRepairDetail.all).to contain_exactly(new_repair_detail)
      end
    end

    shared_examples 'does not enqueue record repair detail jobs' do
      it 'does not enqueue record repair detail jobs' do
        expect(ContainerRegistry::RecordDataRepairDetailWorker).not_to receive(:perform_with_capacity)

        perform
      end
    end

    context 'when on gitlab.com', :saas do
      context 'when the gitlab api is supported' do
        let(:relation) { instance_double(ActiveRecord::Relation) }

        before do
          allow(::Gitlab).to receive(:com_except_jh?).and_return(true)
          allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
          allow(Project).to receive(:pending_data_repair_analysis).and_return(relation)
        end

        context 'when there are pending projects to analyze' do
          before do
            allow(relation).to receive(:exists?).and_return(true)
          end

          it "enqueues record repair detail jobs" do
            expect(ContainerRegistry::RecordDataRepairDetailWorker).to receive(:perform_with_capacity)

            perform
          end
        end

        context 'when there are no pending projects to analyze' do
          before do
            allow(relation).to receive(:exists?).and_return(false)
          end

          it_behaves_like 'does not enqueue record repair detail jobs'
        end
      end

      context 'when the Gitlab API is not supported' do
        before do
          allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
        end

        it_behaves_like 'does not enqueue record repair detail jobs'
      end
    end

    context 'when not on Gitlab.com' do
      it_behaves_like 'does not enqueue record repair detail jobs'
    end

    context 'when registry_data_repair_worker feature is disabled' do
      before do
        stub_feature_flags(registry_data_repair_worker: false)
      end

      it_behaves_like 'does not enqueue record repair detail jobs'
    end
  end
end
