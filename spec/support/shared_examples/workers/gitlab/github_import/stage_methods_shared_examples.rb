# frozen_string_literal: true

RSpec.shared_examples Gitlab::GithubImport::StageMethods do
  let_it_be(:project) { create(:project, :import_started, import_url: 'https://t0ken@github.com/repo/repo.git') }

  describe '.sidekiq_retries_exhausted' do
    it 'tracks the exception and marks the import as failed' do
      expect(Gitlab::Import::ImportFailureService).to receive(:track)
        .with(
          project_id: 1,
          exception: StandardError,
          fail_import: true,
          error_source: anything
        )

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => [1] }, StandardError.new)
    end
  end

  describe '.sidekiq_options' do
    subject(:sidekiq_options) { worker.class.sidekiq_options }

    it 'has a status_expiration' do
      is_expected.to include('status_expiration' => Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)
    end

    it 'has a retry of 6' do
      is_expected.to include('retry' => 6)
    end
  end

  describe '#perform' do
    it 'returns if no project could be found' do
      expect(worker).not_to receive(:import)

      worker.perform(-1)
    end

    it 'returns if the import state is no longer in progress' do
      project.import_state.fail_op!

      expect(worker).not_to receive(:import)

      expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            {
              message: 'starting stage',
              project_id: project.id,
              import_stage: described_class.name
            }
          )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'Project import is no longer running. Stopping worker.',
            project_id: project.id,
            import_stage: described_class.name,
            import_status: 'failed'
          }
        )

      worker.perform(project.id)
    end

    it 'imports the data when the project exists' do
      expect(worker)
        .to receive(:import)
        .with(
          an_instance_of(Gitlab::GithubImport::Client),
          an_instance_of(Project)
        )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'starting stage',
            project_id: project.id,
            import_stage: described_class.name
          }
        )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'stage finished',
            project_id: project.id,
            import_stage: described_class.name
          }
        )

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

    describe 'rescheduling the worker on certain errors' do
      using RSpec::Parameterized::TableSyntax

      where(:error) { [Gitlab::GithubImport::RateLimitError, Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError] }

      with_them do
        it 'reschedules the worker' do
          rate_limit_reset = 10
          client = instance_double(Gitlab::GithubImport::Client, rate_limit_resets_in: rate_limit_reset)

          allow(Gitlab::GithubImport)
            .to receive(:new_client_for)
            .and_return(client)

          expect(worker)
            .to receive(:import)
            .with(client, project)
            .and_raise(error)

          expect(worker.class)
            .to receive(:perform_in)
            .with(rate_limit_reset, project.id)

          expect(Gitlab::GithubImport::Logger)
            .to receive(:info)
            .with(
              {
                message: 'starting stage',
                project_id: project.id,
                import_stage: described_class.name
              }
            )

          expect(Gitlab::GithubImport::Logger)
            .to receive(:info)
            .with(
              {
                message: 'stage retrying',
                project_id: project.id,
                import_stage: described_class.name,
                exception_class: error.name
              }
            )

          worker.perform(project.id)
        end
      end
    end

    it 'logs error when import fails with a StandardError' do
      exception = StandardError.new('some error')

      expect(worker)
        .to receive(:import)
        .and_raise(exception)

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'starting stage',
            project_id: project.id,
            import_stage: described_class.name
          }
        )

      expect(Gitlab::Import::ImportFailureService)
        .to receive(:track)
        .with(
          {
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            fail_import: false,
            metrics: true
          }
        ).and_call_original

      expect { worker.perform(project.id) }
        .to raise_error(exception)

      expect(project.import_state.reload.status).to eq('started')

      expect(project.import_failures).not_to be_empty
      expect(project.import_failures.last.exception_class).to eq('StandardError')
      expect(project.import_failures.last.exception_message).to eq('some error')
    end
  end
end
