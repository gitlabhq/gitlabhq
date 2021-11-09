# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage do
  let(:pipelines) do
    [
      [0, BulkImports::Projects::Pipelines::ProjectPipeline],
      [1, BulkImports::Projects::Pipelines::RepositoryPipeline],
      [2, BulkImports::Common::Pipelines::LabelsPipeline],
      [3, BulkImports::Projects::Pipelines::IssuesPipeline],
      [4, BulkImports::Common::Pipelines::BoardsPipeline],
      [4, BulkImports::Projects::Pipelines::MergeRequestsPipeline],
      [4, BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline],
      [5, BulkImports::Common::Pipelines::WikiPipeline],
      [5, BulkImports::Common::Pipelines::UploadsPipeline],
      [6, BulkImports::Common::Pipelines::EntityFinisher]
    ]
  end

  subject do
    bulk_import = build(:bulk_import)

    described_class.new(bulk_import)
  end

  describe '#pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(subject.pipelines).to eq(pipelines)
    end
  end
end
