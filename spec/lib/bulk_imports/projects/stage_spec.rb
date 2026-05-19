# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage, feature_category: :importers do
  let(:entity) { build(:bulk_import_entity, :project_entity) }

  subject(:stage) { described_class.new(entity) }

  describe '#pipelines' do
    it 'lists all the pipelines' do
      pipelines = stage.pipelines

      expect(pipelines).to include(
        hash_including({ stage: 0, pipeline: BulkImports::Projects::Pipelines::ProjectPipeline }),
        hash_including({ stage: 1, pipeline: BulkImports::Projects::Pipelines::RepositoryPipeline }),
        hash_including({ stage: 5, pipeline: BulkImports::Projects::Pipelines::ReferencesPipeline })
      )
      expect(pipelines.last).to match(hash_including({ pipeline: BulkImports::Common::Pipelines::EntityFinisher }))
    end

    it_behaves_like 'a BulkImports::Stage'

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
