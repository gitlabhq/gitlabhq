# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage, feature_category: :importers do
  let(:ancestor) { create(:group) }
  let(:group) { build(:group, parent: ancestor) }
  let(:bulk_import) { build(:bulk_import) }
  let(:entity) do
    build(:bulk_import_entity, bulk_import: bulk_import, group: group, destination_namespace: ancestor.full_path)
  end

  subject(:stage) { described_class.new(entity) }

  it 'raises error when initialized without a BulkImport' do
    expect { described_class.new({}) }.to raise_error(
      ArgumentError, 'Expected an argument of type ::BulkImports::Entity'
    )
  end

  describe '#pipelines' do
    it 'lists all the pipelines' do
      pipelines = stage.pipelines

      expect(pipelines).to include(
        hash_including({
          pipeline: BulkImports::Groups::Pipelines::GroupPipeline,
          stage: 0
        }),
        hash_including({
          pipeline: BulkImports::Groups::Pipelines::GroupAttributesPipeline,
          stage: 1
        })
      )
      expect(pipelines.last).to match(hash_including({ pipeline: BulkImports::Common::Pipelines::EntityFinisher }))
    end

    it_behaves_like 'a BulkImports::Stage'

    it 'includes project entities pipeline' do
      expect(described_class.new(entity).pipelines).to include(
        hash_including({ pipeline: BulkImports::Groups::Pipelines::ProjectEntitiesPipeline })
      )
    end

    describe 'migrate projects flag' do
      context 'when true' do
        it 'includes project entities pipeline' do
          entity.update!(migrate_projects: true)

          expect(described_class.new(entity).pipelines).to include(
            hash_including({ pipeline: BulkImports::Groups::Pipelines::ProjectEntitiesPipeline })
          )
        end
      end

      context 'when false' do
        it 'does not include project entities pipeline' do
          entity.update!(migrate_projects: false)

          expect(described_class.new(entity).pipelines).not_to include(
            hash_including({ pipeline: BulkImports::Groups::Pipelines::ProjectEntitiesPipeline })
          )
        end
      end
    end

    context 'when destination namespace is not present' do
      it 'includes project entities pipeline' do
        entity = create(:bulk_import_entity, destination_namespace: '')

        expect(described_class.new(entity).pipelines).to include(
          hash_including({ pipeline: BulkImports::Groups::Pipelines::ProjectEntitiesPipeline })
        )
      end
    end

    describe 'migrate memberships flag' do
      context 'when true' do
        it 'includes members pipeline' do
          entity.update!(migrate_memberships: true)

          expect(described_class.new(entity).pipelines).to include(
            hash_including({ pipeline: BulkImports::Common::Pipelines::MembersPipeline })
          )
        end
      end

      context 'when false' do
        it 'does not include members pipeline' do
          entity.update!(migrate_memberships: false)

          expect(described_class.new(entity).pipelines).not_to include(
            hash_including({ pipeline: BulkImports::Common::Pipelines::MembersPipeline })
          )
        end
      end
    end
  end
end
