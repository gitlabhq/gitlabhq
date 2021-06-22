# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe BulkImports::Stage do
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
      expect(described_class.pipelines.last.last).to eq(BulkImports::Groups::Pipelines::EntityFinisher)
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
