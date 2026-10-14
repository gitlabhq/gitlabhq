# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatePropagationCronWorker, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'with stuck processing records' do
      let!(:stuck) do
        create(:namespace_state_propagation, :processing, namespace: group,
          started_at: (described_class::STUCK_THRESHOLD + 1.minute).ago)
      end

      let!(:recent) do
        create(:namespace_state_propagation, :processing, namespace: create(:group),
          started_at: 1.minute.ago)
      end

      it 'resets stuck processing records back to pending' do
        worker.perform

        expect(stuck.reload).to be_status_pending
        expect(stuck.started_at).to be_nil
      end

      it 'leaves recently started processing records untouched' do
        worker.perform

        expect(recent.reload).to be_status_processing
      end

      it 'does not re-enqueue recently started processing records' do
        allow(Namespaces::StatePropagationWorker).to receive(:bulk_perform_async_with_contexts)

        worker.perform

        expect(Namespaces::StatePropagationWorker)
          .to have_received(:bulk_perform_async_with_contexts) do |records, **|
            expect(records).not_to include(recent)
          end
      end

      it 'logs how many records were reset and re-enqueued' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:reset_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:reenqueued_count, 1)

        worker.perform
      end
    end

    context 'with pending records' do
      let!(:pending) do
        create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: group)
      end

      it 're-enqueues the pending record with the namespace id and target state name' do
        allow(Namespaces::StatePropagationWorker).to receive(:bulk_perform_async_with_contexts)

        worker.perform

        expect(Namespaces::StatePropagationWorker)
          .to have_received(:bulk_perform_async_with_contexts) do |records, arguments_proc:, context_proc:|
            expect(records.map { |record| arguments_proc.call(record) }).to contain_exactly([group.id, 'archived'])
            expect(records.map { |record| context_proc.call(record) }).to contain_exactly({ namespace: group })
          end
      end
    end

    context 'when a stuck record is reset and then re-enqueued in the same run' do
      let!(:stuck) do
        create(:namespace_state_propagation, :processing, :ancestor_inherited_to_archived,
          namespace: group, started_at: (described_class::STUCK_THRESHOLD + 1.minute).ago)
      end

      it 'enqueues the recovered record' do
        allow(Namespaces::StatePropagationWorker).to receive(:bulk_perform_async_with_contexts)

        worker.perform

        expect(Namespaces::StatePropagationWorker)
          .to have_received(:bulk_perform_async_with_contexts) do |records, arguments_proc:, **|
            expect(records.map { |record| arguments_proc.call(record) }).to contain_exactly([group.id, 'archived'])
          end
      end
    end

    context 'when there are no records' do
      it 'does not enqueue any jobs' do
        expect(Namespaces::StatePropagationWorker).not_to receive(:bulk_perform_async_with_contexts)

        worker.perform
      end

      it 'logs zero counts' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:reset_count, 0)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:reenqueued_count, 0)

        worker.perform
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let!(:pending) do
      create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: group)
    end
  end
end
