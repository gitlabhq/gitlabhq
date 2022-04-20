# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  let(:ancestor) { create(:group) }
  let(:group) { create(:group, parent: ancestor) }
  let(:bulk_import) { build(:bulk_import) }
  let(:entity) { build(:bulk_import_entity, bulk_import: bulk_import, group: group, destination_namespace: ancestor.full_path) }

  let(:pipelines) do
    [
      [0, BulkImports::Groups::Pipelines::GroupPipeline],
      [1, BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline],
      [1, BulkImports::Common::Pipelines::MembersPipeline],
      [1, BulkImports::Common::Pipelines::LabelsPipeline],
      [1, BulkImports::Common::Pipelines::MilestonesPipeline],
      [1, BulkImports::Common::Pipelines::BadgesPipeline],
      [2, BulkImports::Common::Pipelines::BoardsPipeline],
      [2, BulkImports::Common::Pipelines::UploadsPipeline]
    ]
  end

  it 'raises error when initialized without a BulkImport' do
    expect { described_class.new({}) }.to raise_error(ArgumentError, 'Expected an argument of type ::BulkImports::Entity')
  end

  describe '.pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(described_class.new(entity).pipelines & pipelines).to contain_exactly(*pipelines)
      expect(described_class.new(entity).pipelines.last.last).to eq(BulkImports::Common::Pipelines::EntityFinisher)
    end

    context 'when bulk_import_projects feature flag is enabled' do
      it 'includes project entities pipeline' do
        stub_feature_flags(bulk_import_projects: true)

        expect(described_class.new(entity).pipelines).to include([1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline])
      end

      context 'when feature flag is enabled on root ancestor level' do
        it 'includes project entities pipeline' do
          stub_feature_flags(bulk_import_projects: ancestor)

          expect(described_class.new(entity).pipelines).to include([1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline])
        end
      end

      context 'when destination namespace is not present' do
        it 'includes project entities pipeline' do
          stub_feature_flags(bulk_import_projects: true)

          entity = create(:bulk_import_entity, destination_namespace: '')

          expect(described_class.new(entity).pipelines).to include([1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline])
        end
      end
    end

    context 'when bulk_import_projects feature flag is disabled' do
      it 'does not include project entities pipeline' do
        stub_feature_flags(bulk_import_projects: false)

        expect(described_class.new(entity).pipelines.flatten).not_to include(BulkImports::Groups::Pipelines::ProjectEntitiesPipeline)
      end
    end
  end
end
