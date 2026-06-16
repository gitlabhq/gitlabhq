# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TraversalIdsHealingCronWorker, feature_category: :portfolio_management do
  let(:worker) { described_class.new }
  let(:update_worker) { WorkItems::UpdateNamespaceTraversalIdsWorker }
  let(:cursor_key) { described_class::CURSOR_KEY }

  let_it_be(:divergent_project) { create(:project) }
  let_it_be(:divergent_namespace) { divergent_project.project_namespace }
  let_it_be(:divergent_work_item) do
    create(:work_item, project: divergent_project).tap do |work_item|
      work_item.update_column(:namespace_traversal_ids, [-1])
    end
  end

  let_it_be(:aligned_project) { create(:project) }
  let_it_be(:aligned_namespace) { aligned_project.project_namespace }
  let_it_be(:aligned_work_item) { create(:work_item, project: aligned_project) }

  before do
    stub_feature_flags(work_items_traversal_ids_healing_service: true)
    allow(update_worker).to receive(:bulk_perform_async_with_contexts)
    allow(described_class).to receive(:perform_in)
  end

  it_behaves_like 'an idempotent worker'

  describe '#perform', :clean_gitlab_redis_shared_state do
    subject(:perform) { worker.perform }

    let(:enqueued) { capture_enqueued_namespace_ids }

    context 'when a namespace has diverged work items' do
      before do
        enqueued
        set_cursor(divergent_namespace.id - 1)
      end

      it 'enqueues heals for divergent namespaces, skips aligned ones, and logs', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with(
          a_hash_including(message: 'Enqueuing traversal_id heals for divergent namespaces', count: 1,
            namespace_ids: [divergent_namespace.id])
        )

        perform

        expect(enqueued).to include(divergent_namespace.id)
        expect(enqueued).not_to include(aligned_namespace.id)
      end

      it 'heals the divergent work item by enqueuing the worker', :sidekiq_inline do
        allow(update_worker).to receive(:bulk_perform_async_with_contexts).and_call_original

        perform

        expect(divergent_work_item.reload.namespace_traversal_ids).to eq(divergent_namespace.traversal_ids)
      end

      context 'when the runtime limit is hit' do
        before do
          allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
            allow(limiter).to receive(:over_time?).and_return(true)
          end
        end

        it 'self-reschedules, saves cursor, and logs partial result', :aggregate_failures do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:result, a_hash_including(
            heals_enqueued: 1,
            namespaces_scanned: be > 0
          ))

          perform

          expect(described_class).to have_received(:perform_in).with(described_class::RESCHEDULE_DELAY)
          expect(cursor_value).to be > divergent_namespace.id
        end
      end
    end

    context 'when no namespace has diverged' do
      before do
        divergent_work_item.update_column(:namespace_traversal_ids, divergent_namespace.traversal_ids)
        set_cursor(divergent_namespace.id - 1)
      end

      it 'does not enqueue anything or log divergent heals', :aggregate_failures do
        expect(update_worker).not_to receive(:bulk_perform_async_with_contexts)
        expect(Gitlab::AppLogger).not_to receive(:info).with(
          a_hash_including(message: 'Enqueuing traversal_id heals for divergent namespaces')
        )
        perform
      end
    end

    it 'logs heals_enqueued and namespaces_scanned on a complete pass' do
      set_cursor(Namespace.maximum(:id))

      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, {
        heals_enqueued: 0,
        namespaces_scanned: 0
      })

      perform
    end

    it 'deletes the cursor and stops the chain once the pass completes' do
      set_cursor(Namespace.maximum(:id))

      perform

      expect(cursor_absent?).to be(true)
      expect(described_class).not_to have_received(:perform_in)
    end

    it 'resumes from the saved cursor and does not reprocess already-scanned namespaces' do
      enqueued
      set_cursor(divergent_namespace.id)

      perform

      expect(enqueued).not_to include(divergent_namespace.id)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(work_items_traversal_ids_healing_service: false)
      end

      it 'does nothing' do
        expect(update_worker).not_to receive(:bulk_perform_async_with_contexts)
        expect(described_class).not_to receive(:perform_in)

        expect { perform }.not_to change { cursor_value }
      end
    end
  end

  def set_cursor(value)
    Gitlab::Redis::SharedState.with { |redis| redis.set(cursor_key, value) }
  end

  def cursor_value
    Gitlab::Redis::SharedState.with { |redis| redis.get(cursor_key).to_i }
  end

  def cursor_absent?
    Gitlab::Redis::SharedState.with { |redis| redis.get(cursor_key).nil? }
  end

  def capture_enqueued_namespace_ids
    [].tap do |captured|
      allow(update_worker).to receive(:bulk_perform_async_with_contexts) do |ids, **|
        captured.concat(ids)
      end
    end
  end
end
