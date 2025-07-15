# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods
  it_behaves_like Import::ResumableImportJob

  describe '#perform' do
    context 'when the import succeeds' do
      before do
        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::PullRequestsImporter) do |importer|
          allow(importer).to receive(:execute).and_return(Gitlab::JobWaiter.new(2, '123'))
        end
      end

      it 'schedules the next stage' do
        expect(Gitlab::BitbucketServerImport::AdvanceStageWorker).to receive(:perform_async)
          .with(project.id, { '123' => 2 }, :notes)

        worker.perform(project.id)
      end

      it 'logs stage start and finish' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'starting stage', project_id: project.id))
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'stage finished', project_id: project.id))

        worker.perform(project.id)
      end
    end

    context 'when project does not exists' do
      it 'does not call the importer' do
        expect(Gitlab::BitbucketServerImport::Importers::PullRequestsImporter).not_to receive(:new)

        worker.perform(-1)
      end
    end

    context 'when project import state is not `started`' do
      it 'does not call the importer' do
        project = create(:project, :import_canceled)

        expect(Gitlab::BitbucketServerImport::Importers::PullRequestsImporter).not_to receive(:new)

        worker.perform(project.id)
      end
    end

    context 'when the importer fails' do
      it 'does not schedule the next stage and raises error' do
        exception = StandardError.new('Error')

        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::PullRequestsImporter) do |importer|
          allow(importer).to receive(:execute).and_raise(exception)
        end

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            fail_import: false
          ).and_call_original

        expect { worker.perform(project.id) }
          .to not_change { Gitlab::BitbucketServerImport::AdvanceStageWorker.jobs.size }
          .and raise_error(exception)
      end
    end
  end
end
