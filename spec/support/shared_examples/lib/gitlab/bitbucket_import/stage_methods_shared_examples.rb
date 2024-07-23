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
