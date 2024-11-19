# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage, feature_category: :importers do
  let(:entity) { build(:bulk_import_entity, :project_entity) }

  subject { described_class.new(entity) }

  describe '#pipelines' do
    it 'list all the pipelines' do
      pipelines = subject.pipelines

      expect(pipelines).to include(
        hash_including({ stage: 0, pipeline: BulkImports::Projects::Pipelines::ProjectPipeline }),
        hash_including({ stage: 1, pipeline: BulkImports::Projects::Pipelines::RepositoryPipeline }),
        hash_including({ stage: 5, pipeline: BulkImports::Projects::Pipelines::ReferencesPipeline })
      )
      expect(pipelines.last).to match(hash_including({ pipeline: BulkImports::Common::Pipelines::EntityFinisher }))
    end

    it 'only have pipelines with valid keys' do
      pipeline_keys = subject.pipelines.flat_map(&:keys).uniq
      allowed_keys = %i[pipeline stage minimum_source_version maximum_source_version]

      expect(pipeline_keys - allowed_keys).to be_empty
    end

    it 'only has pipelines with valid versions' do
      pipelines = subject.pipelines
      minimum_source_versions = pipelines.collect { _1[:minimum_source_version] }.flatten.compact
      maximum_source_versions = pipelines.collect { _1[:maximum_source_version] }.flatten.compact
      version_regex = /^(\d+)\.(\d+)\.0$/

      expect(minimum_source_versions.all? { version_regex =~ _1 }).to eq(true)
      expect(maximum_source_versions.all? { version_regex =~ _1 }).to eq(true)
    end

    context 'when stages are out of order in the config hash' do
      it 'list all the pipelines ordered by stage' do
        allow_next_instance_of(BulkImports::Projects::Stage) do |stage|
          allow(stage).to receive(:config).and_return(
            {
              a: { stage: 2 },
              b: { stage: 1 },
              c: { stage: 0 },
              d: { stage: 2 }
            }
          )
        end

        expected_stages = subject.pipelines.collect { _1[:stage] }
        expect(expected_stages).to eq([0, 1, 2, 2])
      end
    end

    describe 'migrate memberships flag' do
      context 'when true' do
        it 'includes memberships pipeline' do
          entity.update!(migrate_memberships: true)

          expect(described_class.new(entity).pipelines).to include(
            hash_including({ pipeline: BulkImports::Common::Pipelines::MembersPipeline })
          )
        end
      end

      context 'when false' do
        it 'does not include memberships pipeline' do
          entity.update!(migrate_memberships: false)

          expect(described_class.new(entity).pipelines).not_to include(
            hash_including({ pipeline: BulkImports::Common::Pipelines::MembersPipeline })
          )
        end
      end
    end
  end
end
