# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  let(:pipelines) do
    [
      [0, BulkImports::Groups::Pipelines::GroupPipeline],
      [1, BulkImports::Groups::Pipelines::GroupAvatarPipeline],
      [1, BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline],
      [1, BulkImports::Groups::Pipelines::MembersPipeline],
      [1, BulkImports::Groups::Pipelines::LabelsPipeline],
      [1, BulkImports::Groups::Pipelines::MilestonesPipeline],
      [1, BulkImports::Groups::Pipelines::BadgesPipeline],
      [2, BulkImports::Groups::Pipelines::BoardsPipeline]
    ]
  end

  describe '.pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(described_class.pipelines & pipelines).to eq(pipelines)
      expect(described_class.pipelines.last.last).to eq(BulkImports::Common::Pipelines::EntityFinisher)
    end

    it 'includes project entities pipeline' do
      stub_feature_flags(bulk_import_projects: true)

      expect(described_class.pipelines).to include([1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline])
    end

    context 'when bulk_import_projects feature flag is disabled' do
      it 'does not include project entities pipeline' do
        stub_feature_flags(bulk_import_projects: false)

        expect(described_class.pipelines.flatten).not_to include(BulkImports::Groups::Pipelines::ProjectEntitiesPipeline)
      end
    end
  end
end
