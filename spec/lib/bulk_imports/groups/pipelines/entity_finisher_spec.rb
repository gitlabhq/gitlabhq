# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::EntityFinisher do
  it 'updates the entity status to finished' do
    entity = create(:bulk_import_entity, :started)
    pipeline_tracker = create(:bulk_import_tracker, entity: entity)
    context = BulkImports::Pipeline::Context.new(pipeline_tracker)
    subject = described_class.new(context)

    expect_next_instance_of(Gitlab::Import::Logger) do |logger|
      expect(logger)
        .to receive(:info)
        .with(
          bulk_import_id: entity.bulk_import.id,
          bulk_import_entity_id: entity.id,
          bulk_import_entity_type: entity.source_type,
          pipeline_class: described_class.name,
          message: 'Entity finished'
        )
    end

    expect { subject.run }
      .to change(entity, :status_name).to(:finished)
  end

  context 'when entity is in a final finished or failed state' do
    shared_examples 'performs no state update' do |entity_state|
      it 'does nothing' do
        entity = create(:bulk_import_entity, entity_state)
        pipeline_tracker = create(:bulk_import_tracker, entity: entity)
        context = BulkImports::Pipeline::Context.new(pipeline_tracker)
        subject = described_class.new(context)

        expect { subject.run }
          .not_to change(entity, :status_name)
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

      expect(entity.reload.failed?).to eq(true)
    end
  end
end
