# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::FinishImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started, import_type: :bitbucket_server) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods

  describe '#perform' do
    it 'finalises the import process' do
      expect_next_instance_of(Gitlab::Import::Metrics, :bitbucket_server_importer, project) do |metric|
        expect(metric).to receive(:track_finished_import)
      end

      worker.perform(project.id)

      expect(project.import_state.reload).to be_finished
    end

    context 'when there are no unloaded placeholder references' do
      before do
        allow_next_instance_of(::Import::PlaceholderReferences::Store) do |store|
          allow(store).to receive(:any?).and_return(false)
        end
      end

      it 'does not queue LoadPlaceholderReferencesWorker' do
        expect(Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

        worker.perform(project.id)
      end

      it 'does not re-enqueue itself' do
        expect(described_class).not_to receive(:perform_in)

        worker.perform(project.id)
      end
    end

    context 'when there are unloaded placeholder references' do
      before do
        allow_next_instance_of(::Import::PlaceholderReferences::Store) do |store|
          allow(store).to receive_messages(any?: true, count: 5)
        end
      end

      it 'queues LoadPlaceholderReferencesWorker' do
        expect(Import::LoadPlaceholderReferencesWorker).to receive(:perform_async).with(
          project.import_type,
          project.import_state.id,
          { current_user_id: project.creator.id }
        )

        worker.perform(project.id)
      end

      it 'schedules itself to run again after 30 seconds' do
        expect(described_class).to receive(:perform_in).with(30.seconds, project.id)

        worker.perform(project.id)
      end

      it 'writes a log entry' do
        allow(Gitlab::BitbucketServerImport::Logger).to receive(:info)

        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info)
          .with(
            a_hash_including(
              message: 'Delaying finalization as placeholder references are pending',
              import_stage: 'Gitlab::BitbucketServerImport::Stage::FinishImportWorker',
              placeholder_store_count: 5,
              project_id: project.id
            )
          ).once

        worker.perform(project.id)
      end
    end
  end
end
