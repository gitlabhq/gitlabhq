# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Router::Graphql do
  it 'matches pipelines endpoint' do
    result = match_route('/api/graphql', 'pipelines/id/1')

    expect(result).to be_present
    expect(result.name).to eq 'pipelines_graph'
  end

  it 'matches pipelines endpoint with a prefixed resource header', :aggregate_failures do
    result = match_route('/api/graphql', '/api/graphql:pipelines/id/1')

    expect(result).to be_present
    expect(result.name).to eq 'pipelines_graph'
  end

  it 'does not match a resource header containing only the prefix' do
    expect(match_route('/api/graphql', '/api/graphql:')).to be_nil
  end

  it 'does not match an unrelated resource header' do
    expect(match_route('/api/graphql', 'unrelated')).to be_nil
  end

  it 'has a valid feature category for every route', :aggregate_failures do
    feature_categories = Gitlab::FeatureCategories.default.categories

    described_class::ROUTES.each do |route|
      expect(feature_categories).to include(route.feature_category), "#{route.name} has a category of #{route.feature_category}, which is not valid"
    end
  end

  it 'applies the default urgency for every route', :aggregate_failures do
    described_class::ROUTES.each do |route|
      expect(route.urgency).to be(Gitlab::EndpointAttributes::DEFAULT_URGENCY)
    end
  end

  def match_route(path, header)
    described_class.match(
      double(path_info: path,
        headers: { 'X-GITLAB-GRAPHQL-RESOURCE-ETAG' => header }))
  end

  describe '.cache_key' do
    let(:path) { '/api/graphql' }
    let(:header_value) { 'pipelines/id/1' }
    let(:headers) do
      { 'X-GITLAB-GRAPHQL-RESOURCE-ETAG' => header_value }.compact
    end

    subject do
      described_class.cache_key(double(path: path, headers: headers))
    end

    it 'uses request path and headers as cache key' do
      is_expected.to eq '/api/graphql:pipelines/id/1'
    end

    context 'when the header includes the GraphQL API path' do
      let(:header_value) { '/api/graphql:pipelines/id/1' }

      it 'does not duplicate the path prefix in the cache key' do
        is_expected.to eq '/api/graphql:pipelines/id/1'
      end
    end

    context 'when the header is missing' do
      let(:header_value) {}

      it 'does not raise errors' do
        is_expected.to eq '/api/graphql'
      end
    end

    context 'when the resource header is blank after removing the prefix' do
      where(:header_value) { ['', ' ', '/api/graphql:', '/api/graphql: '] }

      with_them do
        it 'uses only the request path as the cache key' do
          is_expected.to eq '/api/graphql'
        end
      end
    end
  end
end
