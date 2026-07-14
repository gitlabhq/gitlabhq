# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Groups::Pipelines::ProjectEntitiesPipeline, feature_category: :importers do
  describe '#run', :clean_gitlab_redis_shared_state do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:offline_configuration) do
      create(:import_offline_configuration,
        :with_bulk_import,
        entity_prefix_mapping: {
          'root-group' => 'group_1',
          'root-group/source-group' => 'group_2',
          'root-group/source-group/subgroup-1' => 'group_3',
          'root-group/source-group/project-1' => 'project_1',
          'root-group/source-group/project-2' => 'project_2',
          'root-group/source-group/subgroup-1/descendant-project' => 'project_3',
          'root-group/project' => 'project_4',
          'other-root-group/source-group/other-project' => 'project_5',
          'source-group/other-project' => 'project_6'
        }
      )
    end

    let_it_be(:parent_group) { create(:group, name: 'Imported Group', path: 'imported-group') }
    let_it_be_with_reload(:parent_entity) do
      create(:bulk_import_entity,
        :group_entity,
        bulk_import: offline_configuration.bulk_import,
        group: parent_group,
        destination_namespace: parent_group.full_path,
        source_full_path: 'root-group/source-group'
      )
    end

    let_it_be_with_reload(:tracker) do
      create(:bulk_import_tracker, entity: parent_entity, pipeline_name: described_class.to_s)
    end

    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    before_all do
      parent_group.add_owner(user)
    end

    it 'creates entities for the projects', :aggregate_failures do
      expect { pipeline.run }.to change { BulkImports::Entity.count }.by(2)

      project_entities = BulkImports::Entity.where(parent_id: parent_entity.id)

      expect(project_entities.pluck(:source_type).uniq).to contain_exactly('project_entity')
      expect(project_entities.pluck(:source_full_path)).to contain_exactly(
        'root-group/source-group/project-1',
        'root-group/source-group/project-2'
      )

      expect(project_entities.pluck(:destination_namespace).uniq).to contain_exactly(parent_group.full_path)
      expect(project_entities.pluck(:destination_name)).to contain_exactly('project-1', 'project-2')
      expect(project_entities.pluck(:source_xid).uniq).to contain_exactly(nil)
      expect(project_entities.pluck(:organization_id).uniq).to contain_exactly(parent_group.organization_id)
    end

    it 'does not create duplicate entities on rerun', :aggregate_failures do
      expect { pipeline.run }.to change { BulkImports::Entity.count }.by(2)
      expect { pipeline.run }.not_to change { BulkImports::Entity.count }
    end

    context 'when there are no direct descendant projects to import' do
      before do
        offline_configuration.update!(entity_prefix_mapping: {
          'root-group/source-group' => 'group_2',
          'root-group/source-group/subgroup-1' => 'group_3',
          'root-group/source-group/subgroup-1/descendant-project' => 'project_3'
        })
      end

      it 'does not create any entities' do
        expect { pipeline.run }.not_to change { BulkImports::Entity.count }
      end
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }

    it 'has no transformers' do
      expect(described_class.transformers).to be_empty
    end
  end
end
