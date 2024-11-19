# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Router do
  describe '.match', :aggregate_failures do
    context 'with RESTful routes' do
      it 'matches project pipelines endpoint' do
        result = match_route('/my-group/my-project/-/pipelines.json')

        expect(result).to be_present
        expect(result.name).to eq 'project_pipelines'
        expect(result.router).to eq Gitlab::EtagCaching::Router::Rails
        expect(result.urgency).to eq Projects::PipelinesController.urgency_for_action(:index)
      end
    end

    context 'with GraphQL routes' do
      it 'matches pipelines endpoint' do
        result = match_route('/api/graphql', 'pipelines/id/12')

        expect(result).to be_present
        expect(result.name).to eq 'pipelines_graph'
        expect(result.router).to eq Gitlab::EtagCaching::Router::Graphql
        expect(result.urgency).to eq ::Gitlab::EndpointAttributes::DEFAULT_URGENCY
      end

      it 'matches pipeline sha endpoint' do
        result = match_route('/api/graphql', 'pipelines/sha/4asd12lla2jiwjdqw9as32glm8is8hiu8s2c5jsw')

        expect(result).to be_present
        expect(result.name).to eq 'ci_editor'
        expect(result.router).to eq Gitlab::EtagCaching::Router::Graphql
      end
    end
  end

  def match_route(path, header = nil)
    headers = { 'X-GITLAB-GRAPHQL-RESOURCE-ETAG' => header }.compact

    described_class.match(
      double(path_info: path, headers: headers)
    )
  end
end
