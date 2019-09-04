require 'spec_helper'

describe Gitlab::Graphql::Loaders::PipelineForShaLoader do
  include GraphqlHelpers

  describe '#find_last' do
    it 'batch-resolves latest pipeline' do
      project = create(:project, :repository)
      pipeline1 = create(:ci_pipeline, project: project, ref: project.default_branch, sha: project.commit.sha)
      pipeline2 = create(:ci_pipeline, project: project, ref: project.default_branch, sha: project.commit.sha)
      pipeline3 = create(:ci_pipeline, project: project, ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)

      result = batch_sync(max_queries: 1) do
        [pipeline1.sha, pipeline3.sha].map { |sha| described_class.new(project, sha).find_last }
      end

      expect(result).to contain_exactly(pipeline2, pipeline3)
    end
  end
end
