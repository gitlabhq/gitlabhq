# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::FinishImportWorker, feature_category: :importers do
  let_it_be_with_reload(:project) do
    create(:project, :in_group, :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled)
  end

  let_it_be(:import_state) { create(:import_state, :started, project: project) }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#perform' do
    it 'marks the import as finished and reports import statistics' do
      expect(project).to receive(:after_import)
      expect_next_instance_of(Gitlab::Import::Metrics) do |instance|
        expect(instance).to receive(:track_finished_import)
        expect(instance).to receive(:duration).and_return(3.005)
      end

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
              .with(
                {
                  message: 'GitHub project import finished',
                  import_stage: 'Gitlab::GithubImport::Stage::FinishImportWorker',
                  object_counts: {
                    'fetched' => {},
                    'imported' => {}
                  },
                  project_id: project.id,
                  duration_s: 3.01
                }
              )

      worker.import(double(:client), project)
    end

    context 'when the reference store is empty' do
      it 'checks the reference store and does not push placeholder references' do
        allow(described_class).to receive(:perform_in)
        allow(worker).to receive_message_chain(:placeholder_reference_store, :any?).and_return(false)

        expect(Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

        worker.import(double(:client), project)

        expect(described_class).not_to have_received(:perform_in)
      end
    end

    context 'when the reference store is not empty' do
      it 'checks the reference store, queues LoadPlaceholderReferencesWorker, and requeues itself' do
        allow(described_class).to receive(:perform_in)
        allow(worker).to receive_message_chain(:placeholder_reference_store, :any?).and_return(true)
        allow(worker).to receive_message_chain(:placeholder_reference_store, :count).and_return(1)

        expect(Import::LoadPlaceholderReferencesWorker).to receive(:perform_async)

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            {
              message: 'Delaying finalization as placeholder references are pending',
              import_stage: 'Gitlab::GithubImport::Stage::FinishImportWorker',
              placeholder_store_count: 1,
              project_id: project.id
            }
          )

        worker.import(double(:client), project)

        expect(described_class).to have_received(:perform_in).with(30.seconds, project.id)
      end

      context 'when importing into a personal namespace' do
        before do
          project.update!(namespace: create(:namespace))
        end

        it 'does not check the reference store and does not re-enqueue' do
          allow(described_class).to receive(:perform_in)
          allow(worker).to receive_message_chain(:placeholder_reference_store, :any?).and_return(true)

          expect(Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

          worker.import(double(:client), project)

          expect(described_class).not_to have_received(:perform_in)
        end

        context 'and user_mapping_to_personal_namespace_owner is disabled' do
          before do
            project.build_or_assign_import_data(
              data: { user_mapping_to_personal_namespace_owner_enabled: false }
            ).save!
          end

          it 'checks the reference store, queues LoadPlaceholderReferencesWorker, and requeues itself' do
            allow(described_class).to receive(:perform_in)
            allow(worker).to receive_message_chain(:placeholder_reference_store, :any?).and_return(true)
            allow(worker).to receive_message_chain(:placeholder_reference_store, :count).and_return(1)

            expect(Import::LoadPlaceholderReferencesWorker).to receive(:perform_async)

            expect(Gitlab::GithubImport::Logger)
              .to receive(:info)
              .with(
                {
                  message: 'Delaying finalization as placeholder references are pending',
                  import_stage: 'Gitlab::GithubImport::Stage::FinishImportWorker',
                  placeholder_store_count: 1,
                  project_id: project.id
                }
              )

            worker.import(double(:client), project)

            expect(described_class).to have_received(:perform_in).with(30.seconds, project.id)
          end
        end
      end
    end
  end
end
