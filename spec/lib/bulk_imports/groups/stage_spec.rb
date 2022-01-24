# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  let(:bulk_import) { build(:bulk_import) }

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
    expect { described_class.new({}) }.to raise_error(ArgumentError, 'Expected an argument of type ::BulkImport')
  end

  describe '.pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(described_class.new(bulk_import).pipelines & pipelines).to contain_exactly(*pipelines)
      expect(described_class.new(bulk_import).pipelines.last.last).to eq(BulkImports::Common::Pipelines::EntityFinisher)
    end

    it 'includes project entities pipeline' do
      stub_feature_flags(bulk_import_projects: true)

      expect(described_class.new(bulk_import).pipelines).to include([1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline])
    end

    context 'when bulk_import_projects feature flag is disabled' do
      it 'does not include project entities pipeline' do
        stub_feature_flags(bulk_import_projects: false)

        expect(described_class.new(bulk_import).pipelines.flatten).not_to include(BulkImports::Groups::Pipelines::ProjectEntitiesPipeline)
      end
    end
  end
end
