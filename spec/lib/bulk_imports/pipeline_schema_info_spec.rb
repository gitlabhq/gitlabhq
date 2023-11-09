# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::PipelineSchemaInfo, feature_category: :importers do
  let(:entity) { build(:bulk_import_entity, :project_entity) }
  let(:tracker) { build(:bulk_import_tracker, entity: entity, pipeline_name: pipeline_name) }

  let(:pipeline_name) { BulkImports::Common::Pipelines::LabelsPipeline.to_s }

  subject { described_class.new(tracker.pipeline_class, tracker.entity.portable_class) }

  describe '#db_schema' do
    context 'when pipeline defines a relation name which is an association' do
      it 'returns the schema name of the table used by the association' do
        expect(subject.db_schema).to eq(:gitlab_main_cell)
      end
    end

    context 'when pipeline does not define a relation name' do
      let(:pipeline_name) { BulkImports::Common::Pipelines::EntityFinisher.to_s }

      it 'returns nil' do
        expect(subject.db_schema).to eq(nil)
      end
    end

    context 'when pipeline relation name is not an association' do
      let(:pipeline_name) { BulkImports::Projects::Pipelines::CommitNotesPipeline.to_s }

      it 'returns nil' do
        expect(subject.db_schema).to eq(nil)
      end
    end
  end

  describe '#db_table' do
    context 'when pipeline defines a relation name which is an association' do
      it 'returns the name of the table used by the association' do
        expect(subject.db_table).to eq('labels')
      end
    end

    context 'when pipeline does not define a relation name' do
      let(:pipeline_name) { BulkImports::Common::Pipelines::EntityFinisher.to_s }

      it 'returns nil' do
        expect(subject.db_table).to eq(nil)
      end
    end

    context 'when pipeline relation name is not an association' do
      let(:pipeline_name) { BulkImports::Projects::Pipelines::CommitNotesPipeline.to_s }

      it 'returns nil' do
        expect(subject.db_table).to eq(nil)
      end
    end
  end
end
