# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ProcessService, feature_category: :importers do
  describe '#execute' do
    let_it_be_with_reload(:bulk_import) { create(:bulk_import) }

    subject { described_class.new(bulk_import) }

    context 'when no bulk import is found' do
      let(:bulk_import) { nil }

      it 'does nothing' do
        expect(described_class).not_to receive(:process_bulk_import)
        subject.execute
      end
    end

    context 'when bulk import is finished' do
      it 'does nothing' do
        bulk_import.update!(status: 2)

        expect(described_class).not_to receive(:process_bulk_import)
        subject.execute
      end
    end

    context 'when bulk import is failed' do
      it 'does nothing' do
        bulk_import.update!(status: -1)

        expect(described_class).not_to receive(:process_bulk_import)
        subject.execute
      end
    end

    context 'when bulk import has timed out' do
      it 'does nothing' do
        bulk_import.update!(status: 3)

        expect(described_class).not_to receive(:process_bulk_import)
        subject.execute
      end
    end

    context 'when all entities are processed' do
      before do
        bulk_import.update!(status: 1)
        create(:bulk_import_entity, :finished, bulk_import: bulk_import)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)
      end

      it 'marks bulk import as finished' do
        subject.execute

        expect(bulk_import.reload.finished?).to eq(true)
      end

      context 'when placeholder references have not finished being loaded to the database' do
        before do
          allow_next_instance_of(Import::PlaceholderReferences::Store) do |store|
            allow(store).to receive(:empty?).and_return(false)
            allow(store).to receive(:count).and_return(1)
          end
        end

        it 'marks bulk import as finished' do
          subject.execute

          expect(bulk_import.reload.finished?).to eq(true)
        end

        context 'when importer_user_mapping_enabled is enabled' do
          before do
            allow_next_instance_of(Import::BulkImports::EphemeralData) do |ephemeral_data|
              allow(ephemeral_data).to receive(:importer_user_mapping_enabled?).and_return(true)
            end
          end

          it 'logs and re-enqueues the worker' do
            expect(BulkImportWorker).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)
            expect_next_instance_of(BulkImports::Logger) do |logger|
              expect(logger).to receive(:info).with(
                message: 'Placeholder references not finished loading to database',
                bulk_import_id: bulk_import.id,
                placeholder_reference_store_count: 1
              )
            end

            subject.execute

            expect(bulk_import.reload.started?).to eq(true)
          end
        end
      end
    end

    context 'when all entities are failed' do
      it 'marks bulk import as failed' do
        bulk_import.update!(status: 1)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)

        subject.execute

        expect(bulk_import.reload.failed?).to eq(true)
      end
    end

    context 'when maximum allowed number of import entities in progress', :freeze_time do
      let(:updated_at) { 2.hours.ago }

      before do
        bulk_import.update!(status: 1)
        create(:bulk_import_entity, :created, bulk_import: bulk_import, updated_at: updated_at)

        (described_class::DEFAULT_BATCH_SIZE + 1).times do
          create(:bulk_import_entity, :started, bulk_import: bulk_import, updated_at: updated_at)
        end

        create(:bulk_import_entity, :finished, bulk_import: bulk_import, updated_at: updated_at)
      end

      it 're-enqueues itself' do
        expect(BulkImportWorker).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)
        expect(BulkImports::ExportRequestWorker).not_to receive(:perform_async)

        subject.execute
      end

      it 'touches created entities' do
        subject.execute

        created_entities = bulk_import.entities.with_status(:created)
        other_entities = bulk_import.entities - created_entities

        expect(created_entities).to all(have_attributes(updated_at: be > 1.minute.ago))
        expect(other_entities).to all(have_attributes(updated_at: eq(updated_at)))
      end

      context 'when entity with created status was recently updated' do
        let(:updated_at) { 30.minutes.ago }

        it 'does not update any entity' do
          subject.execute

          expect(bulk_import.entities).to all(have_attributes(updated_at: eq(updated_at)))
        end
      end

      context 'when there is no entity with created status' do
        before do
          bulk_import.entities.with_status(:created).update_all(status: 1)
        end

        it 'does not update any entity' do
          subject.execute

          expect(bulk_import.entities).to all(have_attributes(updated_at: eq(updated_at)))
        end
      end
    end

    context 'when bulk import is created' do
      it 'marks bulk import as started' do
        create(:bulk_import_entity, :created, bulk_import: bulk_import)

        subject.execute

        expect(bulk_import.reload.started?).to eq(true)
      end

      it 'creates all the required pipeline trackers' do
        entity_1 = create(:bulk_import_entity, :created, bulk_import: bulk_import)
        entity_2 = create(:bulk_import_entity, :created, bulk_import: bulk_import)

        expect { subject.execute }
          .to change { BulkImports::Tracker.count }
                .by(BulkImports::Groups::Stage.new(entity_1).pipelines.size * 2)

        expect(entity_1.trackers).not_to be_empty
        expect(entity_2.trackers).not_to be_empty
      end

      context 'when there are created entities to process' do
        before do
          stub_const("#{described_class}::DEFAULT_BATCH_SIZE", 1)
        end

        it 'marks a batch of entities as started, enqueues EntityWorker, ExportRequestWorker and reenqueues' do
          create(:bulk_import_entity, :created, bulk_import: bulk_import)
          create(:bulk_import_entity, :created, bulk_import: bulk_import)

          expect(BulkImportWorker).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)
          expect(BulkImports::ExportRequestWorker).to receive(:perform_async).once

          subject.execute

          bulk_import.reload

          expect(bulk_import.entities.map(&:status_name)).to contain_exactly(:created, :started)
        end

        context 'when there are project entities to process' do
          it 'enqueues ExportRequestWorker' do
            create(:bulk_import_entity, :created, :project_entity, bulk_import: bulk_import)

            expect(BulkImports::ExportRequestWorker).to receive(:perform_async).once

            subject.execute
          end
        end
      end
    end

    context 'when importing a group' do
      it 'creates trackers for group entity' do
        entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

        subject.execute

        expect(entity.trackers.to_a).to include(
          have_attributes(
            stage: 0, status_name: :created, relation: BulkImports::Groups::Pipelines::GroupPipeline.to_s
          ),
          have_attributes(
            stage: 1, status_name: :created, relation: BulkImports::Groups::Pipelines::GroupAttributesPipeline.to_s
          )
        )
      end
    end

    context 'when importing a project' do
      it 'creates trackers for project entity' do
        entity = create(:bulk_import_entity, :project_entity, bulk_import: bulk_import)

        subject.execute

        expect(entity.trackers.to_a).to include(
          have_attributes(
            stage: 0, status_name: :created, relation: BulkImports::Projects::Pipelines::ProjectPipeline.to_s
          ),
          have_attributes(
            stage: 1, status_name: :created, relation: BulkImports::Projects::Pipelines::RepositoryPipeline.to_s
          )
        )
      end
    end

    context 'when tracker configuration has a minimum version defined' do
      before do
        allow_next_instance_of(BulkImports::Groups::Stage) do |stage|
          allow(stage).to receive(:config).and_return(
            {
              pipeline1: { pipeline: 'PipelineClass1', stage: 0 },
              pipeline2: { pipeline: 'PipelineClass2', stage: 1, minimum_source_version: '14.10.0' },
              pipeline3: { pipeline: 'PipelineClass3', stage: 1, minimum_source_version: '15.0.0' },
              pipeline5: { pipeline: 'PipelineClass4', stage: 1, minimum_source_version: '15.1.0' },
              pipeline6: { pipeline: 'PipelineClass5', stage: 1, minimum_source_version: '16.0.0' }
            }
          )
        end
      end

      context 'when the source instance version is older than the tracker mininum version' do
        let_it_be(:entity) { create(:bulk_import_entity, :group_entity, bulk_import: bulk_import) }

        before do
          bulk_import.update!(source_version: '15.0.0')
        end

        it 'creates trackers as skipped if version requirement does not meet' do
          subject.execute

          expect(entity.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }).to contain_exactly(
            [:created, 'PipelineClass1'],
            [:created, 'PipelineClass2'],
            [:created, 'PipelineClass3'],
            [:skipped, 'PipelineClass4'],
            [:skipped, 'PipelineClass5']
          )
        end

        it 'logs an info message for the skipped pipelines' do
          expect_next_instance_of(BulkImports::Logger) do |logger|
            expect(logger).to receive(:with_entity).with(entity).and_call_original.twice

            expect(logger).to receive(:info).with(
              message: 'Pipeline skipped as source instance version not compatible with pipeline',
              pipeline_class: 'PipelineClass4',
              minimum_source_version: '15.1.0',
              maximum_source_version: nil
            )

            expect(logger).to receive(:info).with(
              message: 'Pipeline skipped as source instance version not compatible with pipeline',
              pipeline_class: 'PipelineClass5',
              minimum_source_version: '16.0.0',
              maximum_source_version: nil
            )
          end

          subject.execute
        end
      end

      context 'when the source instance version is undefined' do
        it 'creates trackers as created' do
          bulk_import.update!(source_version: nil)
          entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

          subject.execute

          expect(entity.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }).to contain_exactly(
            [:created, 'PipelineClass1'],
            [:created, 'PipelineClass2'],
            [:created, 'PipelineClass3'],
            [:created, 'PipelineClass4'],
            [:created, 'PipelineClass5']
          )
        end
      end
    end

    context 'when tracker configuration has a maximum version defined' do
      before do
        allow_next_instance_of(BulkImports::Groups::Stage) do |stage|
          allow(stage).to receive(:config).and_return(
            {
              pipeline1: { pipeline: 'PipelineClass1', stage: 0 },
              pipeline2: { pipeline: 'PipelineClass2', stage: 1, maximum_source_version: '14.10.0' },
              pipeline3: { pipeline: 'PipelineClass3', stage: 1, maximum_source_version: '15.0.0' },
              pipeline5: { pipeline: 'PipelineClass4', stage: 1, maximum_source_version: '15.1.0' },
              pipeline6: { pipeline: 'PipelineClass5', stage: 1, maximum_source_version: '16.0.0' }
            }
          )
        end
      end

      context 'when the source instance version is older than the tracker maximum version' do
        it 'creates trackers as skipped if version requirement does not meet' do
          bulk_import.update!(source_version: '15.0.0')
          entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

          subject.execute

          expect(entity.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }).to contain_exactly(
            [:created, 'PipelineClass1'],
            [:skipped, 'PipelineClass2'],
            [:created, 'PipelineClass3'],
            [:created, 'PipelineClass4'],
            [:created, 'PipelineClass5']
          )
        end
      end

      context 'when the source instance version is a patch version' do
        it 'creates trackers with the same status as the non-patch source version' do
          bulk_import_1 = create(:bulk_import, source_version: '15.0.1')
          entity_1 = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import_1)

          bulk_import_2 = create(:bulk_import, source_version: '15.0.0')
          entity_2 = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import_2)

          described_class.new(bulk_import_1).execute
          described_class.new(bulk_import_2).execute

          trackers_1 = entity_1.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }
          trackers_2 = entity_2.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }

          expect(trackers_1).to eq(trackers_2)
        end
      end
    end
  end
end
