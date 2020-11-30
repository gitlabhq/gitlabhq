# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting pipeline information nested in a project' do
  include GraphqlHelpers

  let!(:project) { create(:project, :repository, :public) }
  let!(:pipeline) { create(:ci_pipeline, project: project) }
  let!(:current_user) { create(:user) }
  let(:pipeline_graphql_data) { graphql_data['project']['pipeline'] }

  let!(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('pipeline', iid: pipeline.iid.to_s)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'contains pipeline information' do
    post_graphql(query, current_user: current_user)

    expect(pipeline_graphql_data).not_to be_nil
  end

  it 'contains configSource' do
    post_graphql(query, current_user: current_user)

    expect(pipeline_graphql_data.dig('configSource')).to eq('UNKNOWN_SOURCE')
  end

  context 'batching' do
    let!(:pipeline2) { create(:ci_pipeline, project: project, user: current_user, builds: [create(:ci_build, :success)]) }
    let!(:pipeline3) { create(:ci_pipeline, project: project, user: current_user, builds: [create(:ci_build, :success)]) }
    let!(:query) { build_query_to_find_pipeline_shas(pipeline, pipeline2, pipeline3) }

    it 'executes the finder once' do
      mock = double(Ci::PipelinesFinder)
      opts = { iids: [pipeline.iid, pipeline2.iid, pipeline3.iid].map(&:to_s) }

      expect(Ci::PipelinesFinder).to receive(:new).once.with(project, current_user, opts).and_return(mock)
      expect(mock).to receive(:execute).once.and_return(Ci::Pipeline.none)

      post_graphql(query, current_user: current_user)
    end

    it 'keeps the queries under the threshold' do
      control = ActiveRecord::QueryRecorder.new do
        single_pipeline_query = build_query_to_find_pipeline_shas(pipeline)

        post_graphql(single_pipeline_query, current_user: current_user)
      end

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:success)
        expect do
          post_graphql(query, current_user: current_user)
        end.not_to exceed_query_limit(control)
      end
    end
  end

  private

  def build_query_to_find_pipeline_shas(*pipelines)
    pipeline_fields = pipelines.map.each_with_index do |pipeline, idx|
      "pipeline#{idx}: pipeline(iid: \"#{pipeline.iid}\") { sha }"
    end.join(' ')

    graphql_query_for('project', { 'fullPath' => project.full_path }, pipeline_fields)
  end
end
