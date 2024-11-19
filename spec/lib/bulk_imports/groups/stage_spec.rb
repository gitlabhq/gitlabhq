# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage, feature_category: :importers do
  let(:ancestor) { create(:group) }
  let(:group) { build(:group, parent: ancestor) }
  let(:bulk_import) { build(:bulk_import) }
  let(:entity) do
    build(:bulk_import_entity, bulk_import: bulk_import, group: group, destination_namespace: ancestor.full_path)
  end

  it 'raises error when initialized without a BulkImport' do
    expect { described_class.new({}) }.to raise_error(
      ArgumentError, 'Expected an argument of type ::BulkImports::Entity'
    )
  end

  describe '#pipelines' do
    it 'lists all the pipelines' do
      pipelines = described_class.new(entity).pipelines

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

    it 'only has pipelines with valid keys' do
      pipeline_keys = described_class.new(entity).pipelines.flat_map(&:keys).uniq
      allowed_keys = %i[pipeline stage minimum_source_version maximum_source_version]

      expect(pipeline_keys - allowed_keys).to be_empty
    end

    it 'only has pipelines with valid versions' do
      pipelines = described_class.new(entity).pipelines
      minimum_source_versions = pipelines.collect { _1[:minimum_source_version] }.flatten.compact
      maximum_source_versions = pipelines.collect { _1[:maximum_source_version] }.flatten.compact
      version_regex = /^(\d+)\.(\d+)\.0$/

      expect(minimum_source_versions.all? { version_regex =~ _1 }).to eq(true)
      expect(maximum_source_versions.all? { version_regex =~ _1 }).to eq(true)
    end

    context 'when stages are out of order in the config hash' do
      it 'lists all the pipelines ordered by stage' do
        allow_next_instance_of(BulkImports::Groups::Stage) do |stage|
          allow(stage).to receive(:config).and_return(
            {
              a: { stage: 2 },
              b: { stage: 1 },
              c: { stage: 0 },
              d: { stage: 2 }
            }
          )
        end

        expected_stages = described_class.new(entity).pipelines.collect { _1[:stage] }
        expect(expected_stages).to eq([0, 1, 2, 2])
      end
    end

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
