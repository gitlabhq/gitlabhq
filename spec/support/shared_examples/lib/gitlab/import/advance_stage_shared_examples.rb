# frozen_string_literal: true

RSpec.shared_examples Gitlab::Import::AdvanceStage do |factory:|
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:import_state) { create(factory, :started, project: project, jid: '123') }
  let(:worker) { described_class.new }
  let(:next_stage) { 'finish' }

  describe '#perform', :clean_gitlab_redis_shared_state do
    context 'when the project no longer exists' do
      it 'does not perform any work' do
        expect(worker).not_to receive(:wait_for_jobs)

        worker.perform(non_existing_record_id, { '123' => 2 }, next_stage)
      end
    end

    context 'when there are remaining jobs' do
      it 'reschedules itself' do
        freeze_time do
          expect(worker)
            .to receive(:wait_for_jobs)
            .with({ '123' => 2 })
            .and_return({ '123' => 1 })

          expect(described_class)
            .to receive(:perform_in)
            .with(described_class::INTERVAL, project.id, { '123' => 1 }, next_stage, Time.zone.now, 1)

          worker.perform(project.id, { '123' => 2 }, next_stage)
        end
      end

      context 'when the project import is not running' do
        before do
          import_state.update_column(:status, :failed)
        end

        it 'does not perform any work' do
          expect(worker).not_to receive(:wait_for_jobs)
          expect(described_class).not_to receive(:perform_in)

          worker.perform(project.id, { '123' => 2 }, next_stage)
        end

        it 'clears the JobWaiter cache' do
          expect(Gitlab::JobWaiter).to receive(:delete_key).with('123')

          worker.perform(project.id, { '123' => 2 }, next_stage)
        end
      end
    end

    context 'when there are no remaining jobs' do
      before do
        allow(worker)
          .to receive(:wait_for_jobs)
          .with({ '123' => 2 })
          .and_return({})
      end

      it 'schedules the next stage' do
        next_worker = described_class::STAGES[next_stage.to_sym]

        expect_next_found_instance_of(import_state.class) do |state|
          expect(state).to receive(:refresh_jid_expiration).twice
        end

        expect(next_worker).to receive(:perform_async).with(project.id)

        worker.perform(project.id, { '123' => 2 }, next_stage)
      end

      it 'raises KeyError when the stage name is invalid' do
        expect { worker.perform(project.id, { '123' => 2 }, 'kittens') }
          .to raise_error(KeyError)
      end
    end

    context 'on worker timeouts' do
      it 'refreshes timeout and updates counter if jobs have been processed' do
        freeze_time do
          expect(described_class)
            .to receive(:perform_in)
            .with(described_class::INTERVAL, project.id, { '123' => 2 }, next_stage, Time.zone.now, 2)

          worker.perform(project.id, { '123' => 2 }, next_stage, 3.hours.ago, 5)
        end
      end

      it 'converts string timeout argument to time' do
        freeze_time do
          expect_next_instance_of(described_class) do |klass|
            expect(klass).to receive(:handle_timeout)
          end

          worker.perform(project.id, { '123' => 2 }, next_stage, 3.hours.ago.to_s, 2)
        end
      end

      context 'with an optimistic strategy' do
        before do
          project.build_or_assign_import_data(data: { timeout_strategy: "optimistic" })
          project.save!
        end

        it 'advances to next stage' do
          freeze_time do
            next_worker = described_class::STAGES[next_stage.to_sym]

            expect(next_worker).to receive(:perform_async).with(project.id)

            stuck_start_time = 3.hours.ago

            worker.perform(project.id, { '123' => 2 }, next_stage, stuck_start_time, 2)
          end
        end
      end

      context 'with a pessimistic strategy' do
        let(:expected_error_message) { "Failing advance stage, timeout reached with pessimistic strategy" }

        it 'logs error and fails import' do
          freeze_time do
            next_worker = described_class::STAGES[next_stage.to_sym]

            expect(next_worker).not_to receive(:perform_async)
            expect_next_instance_of(described_class) do |klass|
              expect(klass).to receive(:find_import_state).and_call_original
            end
            expect(Gitlab::Import::ImportFailureService)
              .to receive(:track)
              .with(
                import_state: import_state,
                exception: Gitlab::Import::AdvanceStage::AdvanceStageTimeoutError,
                error_source: described_class.name,
                fail_import: true
              )
              .and_call_original

            stuck_start_time = 3.hours.ago

            worker.perform(project.id, { '123' => 2 }, next_stage, stuck_start_time, 2)

            expect(import_state.reload.status).to eq("failed")

            if import_state.is_a?(ProjectImportState)
              expect(import_state.reload.last_error).to eq(expected_error_message)
            else
              expect(import_state.reload.error_message).to eq(expected_error_message)
            end
          end
        end
      end
    end
  end

  describe '#wait_for_jobs' do
    it 'waits for jobs to complete and returns a new pair of keys to wait for' do
      waiter1 = instance_double("Gitlab::JobWaiter", jobs_remaining: 1, key: '123')
      waiter2 = instance_double("Gitlab::JobWaiter", jobs_remaining: 0, key: '456')

      expect(Gitlab::JobWaiter)
        .to receive(:new)
        .ordered
        .with(2, '123')
        .and_return(waiter1)

      expect(Gitlab::JobWaiter)
        .to receive(:new)
        .ordered
        .with(1, '456')
        .and_return(waiter2)

      expect(waiter1)
        .to receive(:wait)
        .with(described_class::BLOCKING_WAIT_TIME)

      expect(waiter2)
        .to receive(:wait)
        .with(described_class::BLOCKING_WAIT_TIME)

      new_waiters = worker.wait_for_jobs({ '123' => 2, '456' => 1 })

      expect(new_waiters).to eq({ '123' => 1 })
    end
  end
end
