require 'spec_helper'

describe 'api', 'routing' do
  context 'when graphql is disabled' do
    before do
      stub_feature_flags(graphql: false)
    end

    it 'does not route to the GraphqlController' do
      expect(get('/api/graphql')).not_to route_to('graphql#execute')
    end

    it 'does not expose graphiql' do
      expect(get('/-/graphql-explorer')).not_to route_to('graphiql/rails/editors#show')
    end
  end

  context 'when graphql is disabled' do
    before do
      stub_feature_flags(graphql: true)
    end

    it 'routes to the GraphqlController' do
      expect(get('/api/graphql')).not_to route_to('graphql#execute')
    end

    it 'exposes graphiql' do
      expect(get('/-/graphql-explorer')).not_to route_to('graphiql/rails/editors#show')
    end
  end
end
