# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage do
  let(:pipelines) do
    [
      [0, BulkImports::Projects::Pipelines::ProjectPipeline],
      [1, BulkImports::Projects::Pipelines::RepositoryPipeline],
      [2, BulkImports::Common::Pipelines::LabelsPipeline],
      [3, BulkImports::Projects::Pipelines::IssuesPipeline],
      [4, BulkImports::Common::Pipelines::EntityFinisher]
    ]
  end

  describe '.pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(described_class.pipelines).to eq(pipelines)
    end
  end
end
