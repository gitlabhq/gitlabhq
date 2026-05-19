# frozen_string_literal: true

RSpec.shared_examples Gitlab::BitbucketImport::StageMethods do
  let_it_be(:project) { create(:project, :import_started, import_url: 'https://bitbucket.org/the-workspace/the-repo') }

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

    it 'does not execute the importer if no project could be found' do
      expect(worker).not_to receive(:import)

      worker.perform(-1)
    end

    it 'does not execute the importer if the import state is no longer in progress' do
      project.import_state.fail_op!

      expect(worker).not_to receive(:import)

      worker.perform(project.id)
    end

    it 'logs error when import fails with a StandardError' do
      exception = StandardError.new('Error')
      allow(worker).to receive(:import).and_raise(exception)

      expect(Gitlab::Import::ImportFailureService)
        .to receive(:track).with(
          hash_including(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name
          )
        ).and_call_original

      expect { worker.perform(project.id) }
        .to raise_error(exception)

      expect(project.import_failures).not_to be_empty
      expect(project.import_failures.last.exception_class).to eq('StandardError')
      expect(project.import_failures.last.exception_message).to eq('Error')
    end

    context 'when the Bitbucket API returns a non-retryable OAuth2 error' do
      let(:oauth_response) do
        # rubocop:disable RSpec/VerifiedDoubles -- Faraday response needed to construct OAuth2::Response
        double(Faraday::Response,
          status: 404,
          headers: { 'content-type' => 'application/json' },
          body: '{"type": "error", "error": {"message": "Repository not found."}}'
        ).tap { |resp| allow(resp).to receive(:on_complete) }
        # rubocop:enable RSpec/VerifiedDoubles
      end

      let(:exception) { OAuth2::Error.new(OAuth2::Response.new(oauth_response)) }

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 'fails the import immediately without re-raising' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            hash_including(
              project_id: project.id,
              exception: an_instance_of(StandardError).and(having_attributes(message: 'Repository not found.')),
              error_source: described_class.name,
              fail_import: true,
              message: 'import failed due to a non-retryable Bitbucket API error',
              extra_attributes: { http_status_code: 404 }
            )
          ).and_call_original

        expect { worker.perform(project.id) }.not_to raise_error
      end

      it 'logs the error details via ImportFailureService' do
        expect(Import::Framework::Logger).to receive(:error).with(
          hash_including(
            message: 'import failed due to a non-retryable Bitbucket API error',
            'exception.message': 'Repository not found.',
            http_status_code: 404,
            project_id: project.id,
            source: described_class.name
          )
        )

        worker.perform(project.id)
      end
    end

    context 'when the Bitbucket API returns an error with a non-Hash JSON body' do
      let(:oauth_response) do
        # rubocop:disable RSpec/VerifiedDoubles -- Faraday response needed to construct OAuth2::Response
        double(Faraday::Response,
          status: 500,
          headers: { 'content-type' => 'application/json' },
          body: '"just a string"'
        ).tap { |resp| allow(resp).to receive(:on_complete) }
        # rubocop:enable RSpec/VerifiedDoubles
      end

      let(:exception) { OAuth2::Error.new(OAuth2::Response.new(oauth_response)) }

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 'falls back to the exception message' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            hash_including(
              exception: an_instance_of(StandardError).and(having_attributes(message: exception.message))
            )
          ).and_call_original

        expect { worker.perform(project.id) }.not_to raise_error
      end
    end

    context 'when the Bitbucket API returns a 410 Gone error' do
      let(:oauth_response) do
        # rubocop:disable RSpec/VerifiedDoubles -- Faraday response needed to construct OAuth2::Response
        double(Faraday::Response,
          status: 410,
          headers: { 'content-type' => 'application/json' },
          body: '{"type": "error", "error": {"message": "Resource no longer exists"}}'
        ).tap { |resp| allow(resp).to receive(:on_complete) }
        # rubocop:enable RSpec/VerifiedDoubles
      end

      let(:exception) { OAuth2::Error.new(OAuth2::Response.new(oauth_response)) }

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 'fails the import with an enriched error message' do
        expected_message = described_class::GONE_MESSAGE

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            hash_including(
              project_id: project.id,
              exception: an_instance_of(StandardError).and(having_attributes(message: expected_message)),
              error_source: described_class.name,
              fail_import: true,
              message: 'import failed due to a non-retryable Bitbucket API error',
              extra_attributes: { http_status_code: 410 }
            )
          ).and_call_original

        expect { worker.perform(project.id) }.not_to raise_error
      end
    end

    context 'when the Bitbucket API returns an OAuth2 error without a response object' do
      let(:exception) { OAuth2::Error.new('unexpected error') }

      before do
        allow(worker).to receive(:import).and_raise(exception)
      end

      it 'fails the import immediately with the raw error message' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            hash_including(
              project_id: project.id,
              exception: an_instance_of(StandardError).and(having_attributes(message: 'unexpected error')),
              error_source: described_class.name,
              fail_import: true,
              message: 'import failed due to a non-retryable Bitbucket API error',
              extra_attributes: {}
            )
          ).and_call_original

        expect { worker.perform(project.id) }.not_to raise_error
      end
    end

    context 'when the import is successful' do
      let(:import_logger_double) { instance_double(Gitlab::BitbucketImport::Logger) }

      before do
        allow(Gitlab::BitbucketImport::Logger).to receive(:build).and_return(import_logger_double.as_null_object)
      end

      it 'executes the import' do
        expect(worker).to receive(:import).with(project).once
        expect(Gitlab::BitbucketImport::Logger).to receive(:info).twice

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

      it 'logs stage start and finish' do
        allow(worker).to receive(:import)

        expect(import_logger_double)
          .to receive(:info)
          .with(
            hash_including(
              message: 'starting stage',
              project_id: project.id
            )
          )
        expect(import_logger_double)
          .to receive(:info)
          .with(
            hash_including(
              message: 'stage finished',
              project_id: project.id
            )
          )

        worker.perform(project.id)
      end
    end
  end
end
