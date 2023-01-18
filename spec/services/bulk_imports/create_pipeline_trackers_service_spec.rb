# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::CreatePipelineTrackersService, feature_category: :importers do
  describe '#execute!' do
    context 'when entity is group' do
      it 'creates trackers for group entity' do
        bulk_import = create(:bulk_import)
        entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

        described_class.new(entity).execute!

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

    context 'when entity is project' do
      it 'creates trackers for project entity' do
        bulk_import = create(:bulk_import)
        entity = create(:bulk_import_entity, :project_entity, bulk_import: bulk_import)

        described_class.new(entity).execute!

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
        let_it_be(:bulk_import) { create(:bulk_import, source_version: '15.0.0') }
        let_it_be(:entity) { create(:bulk_import_entity, :group_entity, bulk_import: bulk_import) }

        it 'creates trackers as skipped if version requirement does not meet' do
          described_class.new(entity).execute!

          expect(entity.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }).to contain_exactly(
            [:created, 'PipelineClass1'],
            [:created, 'PipelineClass2'],
            [:created, 'PipelineClass3'],
            [:skipped, 'PipelineClass4'],
            [:skipped, 'PipelineClass5']
          )
        end

        it 'logs an info message for the skipped pipelines' do
          expect_next_instance_of(Gitlab::Import::Logger) do |logger|
            expect(logger).to receive(:info).with({
              message: 'Pipeline skipped as source instance version not compatible with pipeline',
              bulk_import_entity_id: entity.id,
              bulk_import_id: entity.bulk_import_id,
              bulk_import_entity_type: entity.source_type,
              source_full_path: entity.source_full_path,
              importer: 'gitlab_migration',
              pipeline_name: 'PipelineClass4',
              minimum_source_version: '15.1.0',
              maximum_source_version: nil,
              source_version: '15.0.0'
            })

            expect(logger).to receive(:info).with({
              message: 'Pipeline skipped as source instance version not compatible with pipeline',
              bulk_import_entity_id: entity.id,
              bulk_import_id: entity.bulk_import_id,
              bulk_import_entity_type: entity.source_type,
              source_full_path: entity.source_full_path,
              importer: 'gitlab_migration',
              pipeline_name: 'PipelineClass5',
              minimum_source_version: '16.0.0',
              maximum_source_version: nil,
              source_version: '15.0.0'
            })
          end

          described_class.new(entity).execute!
        end
      end

      context 'when the source instance version is undefined' do
        it 'creates trackers as created' do
          bulk_import = create(:bulk_import, source_version: nil)
          entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

          described_class.new(entity).execute!

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
          bulk_import = create(:bulk_import, source_version: '15.0.0')
          entity = create(:bulk_import_entity, :group_entity, bulk_import: bulk_import)

          described_class.new(entity).execute!

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

          described_class.new(entity_1).execute!
          described_class.new(entity_2).execute!

          trackers_1 = entity_1.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }
          trackers_2 = entity_2.trackers.collect { |tracker| [tracker.status_name, tracker.relation] }

          expect(trackers_1).to eq(trackers_2)
        end
      end
    end
  end
end
