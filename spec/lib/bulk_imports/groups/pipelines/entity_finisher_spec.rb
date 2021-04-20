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

  it 'does nothing when the entity is already finished' do
    entity = create(:bulk_import_entity, :finished)
    pipeline_tracker = create(:bulk_import_tracker, entity: entity)
    context = BulkImports::Pipeline::Context.new(pipeline_tracker)
    subject = described_class.new(context)

    expect { subject.run }
      .not_to change(entity, :status_name)
  end
end
