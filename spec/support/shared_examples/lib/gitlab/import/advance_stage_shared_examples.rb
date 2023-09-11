# frozen_string_literal: true

RSpec.shared_examples Gitlab::Import::AdvanceStage do |factory:|
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:import_state) { create(factory, :started, project: project, jid: '123') }
  let(:worker) { described_class.new }
  let(:next_stage) { :finish }

  describe '#perform', :clean_gitlab_redis_shared_state do
    context 'when the project no longer exists' do
      it 'does not perform any work' do
        expect(worker).not_to receive(:wait_for_jobs)

        worker.perform(non_existing_record_id, { '123' => 2 }, next_stage)
      end
    end

    context 'when there are remaining jobs' do
      it 'reschedules itself' do
        expect(worker)
          .to receive(:wait_for_jobs)
          .with({ '123' => 2 })
          .and_return({ '123' => 1 })

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::INTERVAL, project.id, { '123' => 1 }, next_stage)

        worker.perform(project.id, { '123' => 2 }, next_stage)
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
        next_worker = described_class::STAGES[next_stage]

        expect_next_found_instance_of(import_state.class) do |state|
          expect(state).to receive(:refresh_jid_expiration)
        end

        expect(next_worker).to receive(:perform_async).with(project.id)

        worker.perform(project.id, { '123' => 2 }, next_stage)
      end

      it 'raises KeyError when the stage name is invalid' do
        expect { worker.perform(project.id, { '123' => 2 }, :kittens) }
          .to raise_error(KeyError)
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
