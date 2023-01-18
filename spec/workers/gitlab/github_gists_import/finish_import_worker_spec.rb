# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::FinishImportWorker, :clean_gitlab_redis_cache, feature_category: :importers do
  subject(:worker) { described_class.new }

  let_it_be(:user) { create(:user) }

  describe '#perform', :aggregate_failures do
    context 'when there are no remaining jobs' do
      before do
        allow(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).and_return(nil)
      end

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
        expect(Notify).not_to receive(:github_gists_import_errors_email)
        expect(Gitlab::Cache::Import::Caching).to receive(:expire).and_call_original

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

    context 'when some gists were failed to import' do
      let(:errors) { { '12345' => 'Snippet maximum file count exceeded.' } }
      let(:waiter) { instance_double(Gitlab::JobWaiter, key: :key, jobs_remaining: 0) }
      let(:mail_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

      before do
        allow(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).and_return(errors)
        allow(Gitlab::JobWaiter).to receive(:new).and_return(waiter)
        allow(waiter).to receive(:wait).with(described_class::BLOCKING_WAIT_TIME)
      end

      it 'sends an email to user' do
        expect_next_instance_of(Gitlab::GithubGistsImport::Status) do |status|
          expect(status).to receive(:finish!)
        end
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(user_id: user.id, message: 'GitHub Gists import finished')
        expect(Notify).to receive(:github_gists_import_errors_email)
          .with(user.id, errors).once.and_return(mail_instance)
        expect(mail_instance).to receive(:deliver_now)
        expect(Gitlab::Cache::Import::Caching).to receive(:expire).and_call_original

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
