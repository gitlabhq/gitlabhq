# frozen_string_literal: true

RSpec.shared_examples Gitlab::BitbucketServerImport::ObjectImporter do
  include AfterNextHelpers

  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [1, {}, 'key'], 'jid' => 'jid' } }

    it 'notifies the waiter' do
      expect(Gitlab::JobWaiter).to receive(:notify).with('key', 'jid', ttl: Gitlab::Import::JOB_WAITER_TTL)

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
    end
  end

  describe '#perform' do
    let_it_be(:import_started_project) { create(:project, :import_started) }

    let(:project_id) { project_id }
    let(:waiter_key) { 'key' }

    before do
      allow(Gitlab::JobWaiter).to receive(:notify).with(waiter_key, anything, ttl: Gitlab::Import::JOB_WAITER_TTL)
    end

    shared_examples 'notifies the waiter' do
      specify do
        allow_next(worker.importer_class).to receive(:execute)

        expect(Gitlab::JobWaiter).to receive(:notify).with(waiter_key, anything, ttl: Gitlab::Import::JOB_WAITER_TTL)

        worker.perform(project_id, {}, waiter_key)
      end
    end

    context 'when project does not exist' do
      let(:project_id) { non_existing_record_id }

      it_behaves_like 'notifies the waiter'
    end

    context 'when project has import started' do
      let_it_be(:project) do
        create(:project, :import_started, import_data_attributes: {
          data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
          credentials: { 'token' => 'token' }
        })
      end

      let(:project_id) { project.id }

      it 'calls the importer' do
        expect_next(worker.importer_class, project, kind_of(Hash)).to receive(:execute)

        worker.perform(project_id, {}, waiter_key)
      end

      it_behaves_like 'notifies the waiter'
    end

    context 'when project import has been cancelled' do
      let_it_be(:project_id) { create(:project, :import_canceled).id }

      it 'does not call the importer' do
        expect_next(worker.importer_class).not_to receive(:execute)

        worker.perform(project_id, {}, waiter_key)
      end

      it_behaves_like 'notifies the waiter'
    end

    context 'when project import has failed' do
      let_it_be(:project_id) { create(:project, :import_failed).id }

      it 'does not call the importer' do
        expect_next(worker.importer_class).not_to receive(:execute)

        worker.perform(project_id, {}, waiter_key)
      end

      it_behaves_like 'notifies the waiter'
    end

    context 'when a non-retryable ConnectionError is raised' do
      let_it_be(:project) do
        create(:project, :import_started, import_data_attributes: {
          data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
          credentials: { 'token' => 'token' }
        })
      end

      let(:project_id) { project.id }
      let(:exception) do
        BitbucketServer::Connection::ConnectionError.new('Error 410: Gone', http_status_code: 410)
      end

      before do
        allow_next(worker.importer_class).to receive(:execute).and_raise(exception)
      end

      it 'logs the error without re-raising' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            hash_including(
              project_id: project.id,
              exception: exception,
              fail_import: false
            )
          )

        expect { worker.perform(project_id, {}, waiter_key) }.not_to raise_error
      end

      it_behaves_like 'notifies the waiter'
    end

    context 'when a retryable ConnectionError is raised' do
      let_it_be(:project) do
        create(:project, :import_started, import_data_attributes: {
          data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
          credentials: { 'token' => 'token' }
        })
      end

      let(:project_id) { project.id }
      let(:exception) do
        BitbucketServer::Connection::ConnectionError.new('Error 500: Server Error', http_status_code: 500)
      end

      before do
        allow_next(worker.importer_class).to receive(:execute).and_raise(exception)
      end

      it 're-raises without tracking so Sidekiq can retry' do
        expect(Gitlab::Import::ImportFailureService).not_to receive(:track)

        expect { worker.perform(project_id, {}, waiter_key) }.to raise_error(exception)
      end

      it_behaves_like 'notifies the waiter'
    end
  end
end
