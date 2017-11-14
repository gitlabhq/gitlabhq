require 'spec_helper'

describe Gitlab::GithubImport::ReschedulingMethods do
  let(:worker) do
    Class.new { include(Gitlab::GithubImport::ReschedulingMethods) }.new
  end

  describe '#perform' do
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
      let(:project) { create(:project) }

      it 'notifies any waiters upon successfully importing the data' do
        expect(worker)
          .to receive(:try_import)
          .with(
            an_instance_of(Project),
            an_instance_of(Gitlab::GithubImport::Client),
            { 'number' => 2 }
          )
          .and_return(true)

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
          .and_return(false)

        expect(worker)
          .not_to receive(:notify_waiter)

        expect_any_instance_of(Gitlab::GithubImport::Client)
          .to receive(:rate_limit_resets_in)
          .and_return(14)

        expect(worker.class)
          .to receive(:perform_in)
          .with(14, project.id, { 'number' => 2 }, '123')

        worker.perform(project.id, { 'number' => 2 }, '123')
      end
    end
  end

  describe '#try_import' do
    it 'returns true when the import succeeds' do
      expect(worker)
        .to receive(:import)
        .with(10, 20)

      expect(worker.try_import(10, 20)).to eq(true)
    end

    it 'returns false when the import fails due to hitting the GitHub API rate limit' do
      expect(worker)
        .to receive(:import)
        .with(10, 20)
        .and_raise(Gitlab::GithubImport::RateLimitError)

      expect(worker.try_import(10, 20)).to eq(false)
    end
  end

  describe '#notify_waiter' do
    it 'notifies the waiter if a waiter key is specified' do
      expect(worker)
        .to receive(:jid)
        .and_return('abc123')

      expect(Gitlab::JobWaiter)
        .to receive(:notify)
        .with('123', 'abc123')

      worker.notify_waiter('123')
    end

    it 'does not notify any waiters if no waiter key is specified' do
      expect(Gitlab::JobWaiter)
        .not_to receive(:notify)

      worker.notify_waiter(nil)
    end
  end
end
