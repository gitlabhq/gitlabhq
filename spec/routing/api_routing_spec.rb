require 'spec_helper'

describe 'api', 'routing' do
  context 'when graphql is disabled' do
    before do
      stub_feature_flags(graphql: false)
    end

    it 'does not route to the GraphqlController' do
      expect(post('/api/graphql')).not_to route_to('graphql#execute')
    end
  end

  context 'when graphql is enabled' do
    before do
      stub_feature_flags(graphql: true)
    end

    it 'routes to the GraphqlController' do
      expect(post('/api/graphql')).to route_to('graphql#execute')
    end
  end
end
