# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering project pipeline statistics' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }

  let(:fields) do
    <<~QUERY
      weekPipelinesTotals
      weekPipelinesLabels
      monthPipelinesLabels
      monthPipelinesTotals
      yearPipelinesLabels
      yearPipelinesTotals
    QUERY
  end

  let(:query) do
    graphql_query_for('project',
                      { 'fullPath' => project.full_path },
                      query_graphql_field('pipelineAnalytics', {}, fields))
  end

  before do
    project.add_maintainer(user)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: user)
    end
  end

  it "contains two arrays of 8 elements each for the week pipelines" do
    post_graphql(query, current_user: user)

    expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesTotals).length).to eq(8)
    expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesLabels).length).to eq(8)
  end

  shared_examples 'monthly statistics' do |timestamp, expected_quantity|
    it "contains two arrays of #{expected_quantity} elements each for the month pipelines" do
      travel_to(timestamp) { post_graphql(query, current_user: user) }

      expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesTotals).length).to eq(expected_quantity)
      expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesLabels).length).to eq(expected_quantity)
    end
  end

  it_behaves_like 'monthly statistics', Time.zone.local(2019, 2, 28), 32
  it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 30), 31
  it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 31), 32

  it "contains two arrays of 13 elements each for the year pipelines" do
    post_graphql(query, current_user: user)

    expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesTotals).length).to eq(13)
    expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesLabels).length).to eq(13)
  end
end
