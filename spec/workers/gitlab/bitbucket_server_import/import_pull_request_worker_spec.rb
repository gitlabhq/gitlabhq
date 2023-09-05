# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::ImportPullRequestWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }

  let(:worker) { described_class.new }

  let(:job_waiter_key) { 'ABC' }

  let(:importer_class) { Gitlab::BitbucketServerImport::Importers::PullRequestImporter }

  before do
    allow(worker).to receive(:jid).and_return('jid')
  end

  it_behaves_like Gitlab::BitbucketServerImport::ObjectImporter

  describe '#perform' do
    context 'when the import succeeds' do
      before do
        allow_next_instance_of(importer_class) do |importer|
          allow(importer).to receive(:execute)
        end
      end

      it 'notifies job waiter' do
        expect(Gitlab::JobWaiter).to receive(:notify).with(job_waiter_key, 'jid', ttl: Gitlab::Import::JOB_WAITER_TTL)

        worker.perform(project.id, {}, job_waiter_key)
      end

      it 'logs stage start and finish' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'importer started', project_id: project.id))
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'importer finished', project_id: project.id))

        worker.perform(project.id, {}, job_waiter_key)
      end
    end

    context 'when project does not exists' do
      it 'does not call importer and notifies job waiter' do
        expect(importer_class).not_to receive(:new)
        expect(Gitlab::JobWaiter).to receive(:notify).with(job_waiter_key, 'jid', ttl: Gitlab::Import::JOB_WAITER_TTL)

        worker.perform(-1, {}, job_waiter_key)
      end
    end

    context 'when project import state is not `started`' do
      it 'does not call importer' do
        project = create(:project, :import_canceled)

        expect(importer_class).not_to receive(:new)
        expect(Gitlab::JobWaiter).to receive(:notify).with(job_waiter_key, 'jid', ttl: Gitlab::Import::JOB_WAITER_TTL)

        worker.perform(project.id, {}, job_waiter_key)
      end
    end

    context 'when the importer fails' do
      it 'raises an error' do
        exception = StandardError.new('Error')

        allow_next_instance_of(importer_class) do |importer|
          allow(importer).to receive(:execute).and_raise(exception)
        end

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            project_id: project.id,
            exception: exception,
            error_source: importer_class.name,
            fail_import: false
          ).and_call_original

        expect { worker.perform(project.id, {}, job_waiter_key) }.to raise_error(exception)
      end
    end
  end
end
