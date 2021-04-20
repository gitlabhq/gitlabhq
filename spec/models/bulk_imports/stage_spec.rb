# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Stage do
  let(:pipelines) do
    if Gitlab.ee?
      [
        [0, BulkImports::Groups::Pipelines::GroupPipeline],
        [1, BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline],
        [1, BulkImports::Groups::Pipelines::MembersPipeline],
        [1, BulkImports::Groups::Pipelines::LabelsPipeline],
        [1, BulkImports::Groups::Pipelines::MilestonesPipeline],
        [1, BulkImports::Groups::Pipelines::BadgesPipeline],
        [1, 'BulkImports::Groups::Pipelines::IterationsPipeline'.constantize],
        [2, 'BulkImports::Groups::Pipelines::EpicsPipeline'.constantize],
        [3, 'BulkImports::Groups::Pipelines::EpicAwardEmojiPipeline'.constantize],
        [3, 'BulkImports::Groups::Pipelines::EpicEventsPipeline'.constantize],
        [4, BulkImports::Groups::Pipelines::EntityFinisher]
      ]
    else
      [
        [0, BulkImports::Groups::Pipelines::GroupPipeline],
        [1, BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline],
        [1, BulkImports::Groups::Pipelines::MembersPipeline],
        [1, BulkImports::Groups::Pipelines::LabelsPipeline],
        [1, BulkImports::Groups::Pipelines::MilestonesPipeline],
        [1, BulkImports::Groups::Pipelines::BadgesPipeline],
        [2, BulkImports::Groups::Pipelines::EntityFinisher]
      ]
    end
  end

  describe '.pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(described_class.pipelines).to match_array(pipelines)
    end
  end

  describe '.pipeline_exists?' do
    it 'returns true when the given pipeline name exists in the pipelines list' do
      expect(described_class.pipeline_exists?(BulkImports::Groups::Pipelines::GroupPipeline)).to eq(true)
      expect(described_class.pipeline_exists?('BulkImports::Groups::Pipelines::GroupPipeline')).to eq(true)
    end

    it 'returns false when the given pipeline name exists in the pipelines list' do
      expect(described_class.pipeline_exists?('BulkImports::Groups::Pipelines::InexistentPipeline')).to eq(false)
    end
  end
end
