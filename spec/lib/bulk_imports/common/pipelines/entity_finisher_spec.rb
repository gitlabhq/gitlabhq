# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::EntityFinisher, feature_category: :importers do
  it 'updates the entity status to finished' do
    entity = create(:bulk_import_entity, :project_entity, :started)
    pipeline_tracker = create(:bulk_import_tracker, entity: entity)
    context = BulkImports::Pipeline::Context.new(pipeline_tracker)
    subject = described_class.new(context)

    expect_next_instance_of(BulkImports::Logger) do |logger|
      expect(logger).to receive(:with_entity).with(entity).and_call_original

      expect(logger)
        .to receive(:info)
        .with(
          pipeline_class: described_class.name,
          message: 'Entity finished'
        )
    end

    expect(BulkImports::FinishProjectImportWorker).to receive(:perform_async).with(entity.project_id)

    expect { subject.run }
      .to change { entity.status_name }.to(:finished)
  end

  context 'when entity is in a final finished or failed state' do
    shared_examples 'performs no state update' do |entity_state|
      it 'does nothing' do
        entity = create(:bulk_import_entity, entity_state)
        pipeline_tracker = create(:bulk_import_tracker, entity: entity)
        context = BulkImports::Pipeline::Context.new(pipeline_tracker)
        subject = described_class.new(context)

        expect { subject.run }
          .not_to change { entity.status_name }
      end
    end

    include_examples 'performs no state update', :finished
    include_examples 'performs no state update', :failed
  end

  context 'when all entity trackers failed' do
    it 'marks entity as failed' do
      entity = create(:bulk_import_entity, :started)
      create(:bulk_import_tracker, :failed, entity: entity)
      pipeline_tracker = create(:bulk_import_tracker, entity: entity, relation: described_class)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      described_class.new(context).run

      expect(entity.reload.failed?).to be(true)
    end

    it 'does not track the finish_project_import internal event' do
      entity = create(:bulk_import_entity, :project_entity, :started)
      create(:bulk_import_tracker, :failed, entity: entity)
      pipeline_tracker = create(:bulk_import_tracker, entity: entity, relation: described_class)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      expect { described_class.new(context).run }
        .not_to trigger_internal_events('finish_project_import')
    end
  end

  context 'when entity finishes successfully' do
    it 'tracks the finish_project_import internal event for project entities' do
      entity = create(:bulk_import_entity, :project_entity, :started,
        project: create(:project, import_type: 'gitlab_project_migration'),
        bulk_import: create(:bulk_import, :with_configuration))
      pipeline_tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      expect { described_class.new(context).run }
        .to trigger_internal_events('finish_project_import')
        .with(
          project: entity.project,
          user: entity.bulk_import.user,
          namespace: entity.project.namespace,
          additional_properties: { label: 'gitlab_project_migration', property: entity.hashed_import_source }
        )
    end

    it 'does not track the finish_project_import event for group entities' do
      entity = create(:bulk_import_entity, :group_entity, :started)
      pipeline_tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      expect { described_class.new(context).run }
        .not_to trigger_internal_events('finish_project_import')
    end

    it 'tracks the finish_project_import internal event for offline entities, labeled as offline_transfer' do
      entity = create(
        :bulk_import_entity, :project_entity, :started,
        project: create(:project, import_type: 'offline_transfer'),
        bulk_import: create(:bulk_import, :with_offline_configuration)
      )
      pipeline_tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      expect { described_class.new(context).run }
        .to trigger_internal_events('finish_project_import')
        .with(
          project: entity.project,
          user: entity.bulk_import.user,
          namespace: entity.project.namespace,
          additional_properties: { label: 'offline_transfer', property: entity.hashed_import_source }
        )
    end
  end

  context 'when entity is a group' do
    it 'schedules PlacementWorker so imported epics get positioned' do
      group = create(:group)
      entity = create(:bulk_import_entity, :group_entity, :started, group: group)
      pipeline_tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(pipeline_tracker)

      expect(::Issues::PlacementWorker)
        .to receive(:perform_async)
        .with({ 'namespace_id' => group.work_item_positioning_root.id })

      described_class.new(context).run
    end
  end
end
