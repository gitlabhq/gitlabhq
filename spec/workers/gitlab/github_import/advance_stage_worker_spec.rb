require 'spec_helper'

describe Gitlab::GithubImport::AdvanceStageWorker, :clean_gitlab_redis_shared_state do
  let(:project) { create(:project, import_jid: '123') }
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
          .to receive(:find_project)
          .and_return(project)
      end

      it 'reschedules itself' do
        expect(worker)
          .to receive(:wait_for_jobs)
          .with({ '123' => 2 })
          .and_return({ '123' => 1 })

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::INTERVAL, project.id, { '123' => 1 }, :finish)

        worker.perform(project.id, { '123' => 2 }, :finish)
      end
    end

    context 'when there are no remaining jobs' do
      before do
        allow(worker)
          .to receive(:find_project)
          .and_return(project)

        allow(worker)
          .to receive(:wait_for_jobs)
          .with({ '123' => 2 })
          .and_return({})
      end

      it 'schedules the next stage' do
        expect(project)
          .to receive(:refresh_import_jid_expiration)

        expect(Gitlab::GithubImport::Stage::FinishImportWorker)
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
      waiter1 = double(:waiter1, jobs_remaining: 1, key: '123')
      waiter2 = double(:waiter2, jobs_remaining: 0, key: '456')

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

  describe '#find_project' do
    it 'returns a Project' do
      project.update_column(:import_status, 'started')

      found = worker.find_project(project.id)

      expect(found).to be_an_instance_of(Project)

      # This test is there to make sure we only select the columns we care
      # about.
      expect(found.attributes).to eq({ 'id' => nil, 'import_jid' => '123' })
    end

    it 'returns nil if the project import is not running' do
      expect(worker.find_project(project.id)).to be_nil
    end
  end
end
