# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::Projects::Stage, feature_category: :importers do
  let(:entity) { build(:bulk_import_entity, :project_entity) }

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
          pipeline: Import::Offline::Projects::Pipelines::ProjectPipeline,
          stage: 0
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::MaxIidsPipeline,
          stage: 1
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::RepositoryBundlePipeline,
          stage: 1
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::LabelsPipeline,
          stage: 2
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::MilestonesPipeline,
          stage: 2
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::IssuesPipeline,
          stage: 3
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::BoardsPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::MergeRequestsPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ProtectedBranchesPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ProjectFeaturePipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ContainerExpirationPolicyPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ServiceDeskSettingPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ReleasesPipeline,
          stage: 4
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::CiPipelinesPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::CommitNotesPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::UploadsPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::LfsObjectsPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::DesignBundlePipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::AutoDevopsPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::PipelineSchedulesPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: BulkImports::Projects::Pipelines::ReferencesPipeline,
          stage: 5
        }),
        hash_including({
          pipeline: Import::Offline::Common::Pipelines::UserContributionsPipeline,
          stage: 6
        }),
        hash_including({
          pipeline: BulkImports::Common::Pipelines::EntityFinisher,
          stage: 7
        })
      )
    end

    it_behaves_like 'a BulkImports::Stage'
  end
end
