# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::ScheduleDestroyCronWorker, feature_category: :infrastructure_as_code do
  subject(:worker) { described_class.new }

  describe 'worker configuration' do
    it 'has low urgency' do
      expect(described_class.get_urgency).to eq(:low)
    end

    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'deduplicates until executed' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end
  end

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { worker.perform }

    let_it_be(:project) { create(:project) }

    let_it_be(:state_not_deleted) do
      create(:terraform_state, project: project)
    end

    let_it_be(:state_within_grace_period) do
      create(:terraform_state, project: project,
        deleted_at: (Terraform::State::GRACE_PERIOD - 1.minute).ago)
    end

    let_it_be(:state_past_grace_period) do
      create(:terraform_state, project: project,
        deleted_at: (Terraform::State::GRACE_PERIOD + 1.minute).ago)
    end

    let_it_be(:state_past_grace_period_two) do
      create(:terraform_state, project: project,
        deleted_at: (Terraform::State::GRACE_PERIOD + 2.minutes).ago)
    end

    # The exact match covers three cases using all four states: both past-grace states
    # must be enqueued, and the not-deleted and within-grace states must not be, because
    # any extra element fails match_array.
    it 'enqueues only states past the grace period' do
      expect(Terraform::States::DestroyWorker).to receive(:bulk_perform_async)
        .with(match_array([[state_past_grace_period.id], [state_past_grace_period_two.id]]))

      perform
    end

    it 'does not cause N+1 queries for project context' do
      create(:terraform_state, project: create(:project), deleted_at: 8.days.ago)
      control = ActiveRecord::QueryRecorder.new { worker.perform }

      create_list(:terraform_state, 2, deleted_at: 8.days.ago)

      expect { worker.perform }.not_to exceed_query_limit(control)
    end

    context 'when there are no states ready for destruction' do
      before do
        allow(Terraform::State).to receive(:ready_for_destruction).and_return(Terraform::State.none)
      end

      it 'does not enqueue any DestroyWorker jobs' do
        expect(Terraform::States::DestroyWorker).not_to receive(:bulk_perform_async)

        perform
      end
    end

    context 'when states span multiple batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'enqueues DestroyWorker for states in every batch' do
        expect(Terraform::States::DestroyWorker).to receive(:bulk_perform_async)
          .with([[state_past_grace_period.id]])
        expect(Terraform::States::DestroyWorker).to receive(:bulk_perform_async)
          .with([[state_past_grace_period_two.id]])

        perform
      end
    end

    context 'when the flag is disabled for a project' do
      let_it_be(:flag_disabled_project) { create(:project) }
      let_it_be(:state_in_flag_disabled_project) do
        create(:terraform_state, project: flag_disabled_project,
          deleted_at: (Terraform::State::GRACE_PERIOD + 1.minute).ago)
      end

      before do
        stub_feature_flags(terraform_state_delayed_deletion: project)
      end

      it 'does not enqueue states in projects where the flag is disabled' do
        expect(Terraform::States::DestroyWorker).to receive(:bulk_perform_async)
          .with(match_array([[state_past_grace_period.id], [state_past_grace_period_two.id]]))

        perform
      end
    end
  end
end
