# frozen_string_literal: true

RSpec.shared_examples Gitlab::BitbucketServerImport::StageMethods do
  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [project.id] } }

    it 'tracks the import failure' do
      expect(Gitlab::Import::ImportFailureService)
        .to receive(:track).with(
          project_id: project.id,
          exception: StandardError.new,
          fail_import: true
        )

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }

    it 'executes the import' do
      expect(worker).to receive(:import).with(project).once
      expect(Gitlab::BitbucketServerImport::Logger).to receive(:info).twice

      worker.perform(project.id)
    end

    it 'queues RefreshImportJidWorker' do
      allow(worker).to receive(:import)
      allow(worker).to receive(:jid).and_return('mock_jid')

      expect(Gitlab::Import::RefreshImportJidWorker)
        .to receive(:perform_in_the_future)
        .with(project.id, 'mock_jid')

      worker.perform(project.id)
    end

    context 'when a non-retryable ConnectionError is raised' do
      let(:exception) do
        BitbucketServer::Connection::ConnectionError.new('Error 404: Not Found', http_status_code: 404)
      end

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 'fails the import immediately without re-raising' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            fail_import: true
          )

        expect { worker.perform(project.id) }.not_to raise_error
      end

      it 'logs a warning with the HTTP status code' do
        expect(Gitlab::BitbucketServerImport::Logger).to receive(:warn).with(
          hash_including(
            message: 'Non-retryable Bitbucket Server error, failing import',
            http_status_code: 404,
            error: 'Error 404: Not Found'
          )
        )

        worker.perform(project.id)
      end
    end

    context 'when a retryable ConnectionError is raised' do
      let(:exception) do
        BitbucketServer::Connection::ConnectionError.new('Error 500: Internal Server Error', http_status_code: 500)
      end

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 're-raises without tracking so Sidekiq can retry' do
        expect(Gitlab::Import::ImportFailureService).not_to receive(:track)

        expect { worker.perform(project.id) }.to raise_error(exception)
      end
    end
  end
end
