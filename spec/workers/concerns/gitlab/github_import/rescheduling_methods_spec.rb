# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ReschedulingMethods, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:worker) do
    Class.new do
      def self.name
        'MockImportWorker'
      end

      def object_type
        :pull_request
      end

      def parallel_import_batch
        { size: 1, delay: 1.minute }
      end

      include ApplicationWorker
      include Gitlab::GithubImport::ReschedulingMethods
    end.new
  end

  describe '#perform' do
    let_it_be(:project) { create(:project, import_url: 'https://t0ken@github.com/repo/repo.git') }

    context 'with a non-existing project' do
      it 'does not perform any work' do
        expect(worker)
          .not_to receive(:try_import)

        worker.perform(-1, {})
      end

      it 'notifies any waiters so they do not wait forever' do
        expect(worker)
          .to receive(:notify_waiter)
          .with('123')

        worker.perform(-1, {}, '123')
      end
    end

    context 'with an existing project' do
      before do
        allow_next_instance_of(Gitlab::GithubImport::Client) do |instance|
          allow(instance).to receive(:rate_limit_resets_in).and_return(14)
        end
      end

      it 'notifies any waiters upon successfully importing the data' do
        expect(worker)
          .to receive(:try_import)
          .with(
            an_instance_of(Project),
            an_instance_of(Gitlab::GithubImport::Client),
            { 'number' => 2 }
          )
          .and_return({ success: true })

        expect(worker)
          .to receive(:notify_waiter).with('123')

        worker.perform(project.id, { 'number' => 2 }, '123')
      end

      it 'reschedules itself if the data could not be imported' do
        expect(worker)
          .to receive(:try_import)
          .with(
            an_instance_of(Project),
            an_instance_of(Gitlab::GithubImport::Client),
            { 'number' => 2 }
          )
          .and_return({ success: false })

        expect(worker)
          .not_to receive(:notify_waiter)

        expect(worker)
          .to receive(:object_type)
          .and_return(:pull_request)

        expect(worker.class)
          .to receive(:perform_in)
          .with(75, project.id, { 'number' => 2 }, '123')

        worker.perform(project.id, { 'number' => 2 }, '123')
      end
    end

    describe 'rescheduling due to rate limit' do
      before do
        allow_next_instance_of(Gitlab::GithubImport::Client) do |instance|
          allow(instance).to receive(:rate_limit_resets_in).and_return(15)
        end
      end

      context 'when rate limit error does not specify reset time' do
        before do
          allow(worker).to receive(:import).and_raise(Gitlab::GithubImport::RateLimitError)
        end

        it 'reschedule using client rate_limit_resets_in' do
          expect(worker.class).to receive(:perform_in).with(76, project.id, { 'number' => 2 }, '123')

          worker.perform(project.id, { 'number' => 2 }, '123')
        end
      end

      context 'when rate limit error specifies custom reset time' do
        before do
          allow(worker).to receive(:import).and_raise(Gitlab::GithubImport::RateLimitError.new('Rate limit', 20))
        end

        it 'reschedule using error reset_in value' do
          expect(worker.class).to receive(:perform_in).with(81, project.id, { 'number' => 2 }, '123')

          worker.perform(project.id, { 'number' => 2 }, '123')
        end
      end
    end
  end

  describe '#try_import' do
    it 'returns true when the import succeeds' do
      expect(worker)
        .to receive(:import)
        .with(10, 20)

      expect(worker.try_import(10, 20)).to eq({ success: true })
    end

    it 'returns false when the import fails due to hitting the GitHub API rate limit' do
      expect(worker)
        .to receive(:import)
        .with(10, 20)
        .and_raise(Gitlab::GithubImport::RateLimitError)

      expect(worker.try_import(10, 20)).to eq({ success: false, reset_in: nil })
    end

    it 'returns false when the import fails due to the FailedToObtainLockError' do
      expect(worker)
        .to receive(:import)
        .with(10, 20)
        .and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)

      expect(worker.try_import(10, 20)).to eq({ success: false, reset_in: nil })
    end
  end

  describe '#notify_waiter' do
    it 'notifies the waiter if a waiter key is specified' do
      expect(worker)
        .to receive(:jid)
        .and_return('abc123')

      expect(Gitlab::JobWaiter)
        .to receive(:notify)
        .with('123', 'abc123', ttl: Gitlab::Import::JOB_WAITER_TTL)

      worker.notify_waiter('123')
    end

    it 'does not notify any waiters if no waiter key is specified' do
      expect(Gitlab::JobWaiter)
        .not_to receive(:notify)

      worker.notify_waiter(nil)
    end
  end
end
