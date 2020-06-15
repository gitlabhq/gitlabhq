# frozen_string_literal: true

require 'spec_helper'

describe 'getting pipeline information nested in a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:current_user) { create(:user) }
  let(:pipeline_graphql_data) { graphql_data['project']['pipeline'] }

  let(:query) do
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
end
