# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::AdvanceStageWorker, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project, jid: '123') }
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'when the project no longer exists' do
      it 'does not perform any work' do
        expect(worker).not_to receive(:wait_for_jobs)

        worker.perform(-1, { '123' => 2 }, :finish)
      end
    end

    context 'when there are remaining jobs' do
      before do
        allow(worker)
          .to receive(:find_import_state_jid)
          .and_return(import_state)
      end

      it 'reschedules itself' do
        freeze_time do
          expect(worker)
            .to receive(:wait_for_jobs)
            .with({ '123' => 2 })
            .and_return({ '123' => 1 })

          expect(described_class)
            .to receive(:perform_in)
            .with(described_class::INTERVAL, project.id, { '123' => 1 }, 'finish', Time.zone.now.to_s, 1)

          worker.perform(project.id, { '123' => 2 }, :finish)
        end
      end
    end

    context 'when there are no remaining jobs' do
      before do
        allow(worker)
          .to receive(:find_import_state_jid)
          .and_return(import_state)

        allow(worker)
          .to receive(:wait_for_jobs)
          .with({ '123' => 2 })
          .and_return({})
      end

      it 'schedules the next stage' do
        expect(import_state)
          .to receive(:refresh_jid_expiration).twice

        expect(Gitlab::BitbucketImport::Stage::FinishImportWorker)
          .to receive(:perform_async)
          .with(project.id)

        worker.perform(project.id, { '123' => 2 }, :finish)
      end

      it 'raises KeyError when the stage name is invalid' do
        expect { worker.perform(project.id, { '123' => 2 }, :kittens) }
          .to raise_error(KeyError)
      end
    end
  end

  describe '#wait_for_jobs' do
    it 'waits for jobs to complete and returns a new pair of keys to wait for' do
      waiter1 = instance_double(Gitlab::JobWaiter, jobs_remaining: 1, key: '123')
      waiter2 = instance_double(Gitlab::JobWaiter, jobs_remaining: 0, key: '456')

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

  describe '#find_import_state_jid' do
    it 'returns a ProjectImportState with only id and jid' do
      import_state.update_column(:status, 'started')

      found = worker.find_import_state_jid(project.id)

      expect(found).to be_an_instance_of(ProjectImportState)
      expect(found.attributes.keys).to match_array(%w[id jid])
    end

    it 'returns nil if the project import is not running' do
      expect(worker.find_import_state_jid(project.id)).to be_nil
    end
  end

  describe '#find_import_state' do
    it 'returns a ProjectImportState' do
      import_state.update_column(:status, 'started')

      found_partial = worker.find_import_state_jid(project.id)
      found = worker.find_import_state(found_partial.id)

      expect(found).to be_an_instance_of(ProjectImportState)
      expect(found.attributes.keys).to include('id', 'project_id', 'status', 'last_error')
    end
  end
end
