# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::FinishImportWorker, feature_category: :importer do
  subject(:worker) { described_class.new }

  let_it_be(:user) { create(:user) }

  describe '#perform', :aggregate_failures do
    context 'when there are no remaining jobs' do
      it 'marks import status as finished' do
        waiter = instance_double(Gitlab::JobWaiter, key: :key, jobs_remaining: 0)
        expect(Gitlab::JobWaiter).to receive(:new).and_return(waiter)
        expect(waiter).to receive(:wait).with(described_class::BLOCKING_WAIT_TIME)
        expect_next_instance_of(Gitlab::GithubGistsImport::Status) do |status|
          expect(status).to receive(:finish!)
        end
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(user_id: user.id, message: 'GitHub Gists import finished')

        worker.perform(user.id, waiter.key, waiter.jobs_remaining)
      end
    end

    context 'when there are remaining jobs' do
      it 'reschedules the worker' do
        waiter = instance_double(Gitlab::JobWaiter, key: :key, jobs_remaining: 2)
        expect(Gitlab::JobWaiter).to receive(:new).and_return(waiter)
        expect(waiter).to receive(:wait).with(described_class::BLOCKING_WAIT_TIME)
        expect(described_class).to receive(:perform_in)
          .with(described_class::INTERVAL, user.id, waiter.key, waiter.jobs_remaining)

        worker.perform(user.id, waiter.key, waiter.jobs_remaining)
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'sets status to failed' do
      job = { 'args' => [user.id, 'some_key', '1'], 'jid' => '123' }

      expect_next_instance_of(Gitlab::GithubGistsImport::Status) do |status|
        expect(status).to receive(:fail!)
      end

      described_class.sidekiq_retries_exhausted_block.call(job)
    end
  end
end
