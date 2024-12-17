# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.cluster_agents', feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be(:agents) { create_list(:cluster_agent, 3, project: project) }

  let(:first) { var('Int') }
  let(:cluster_agents_fields) { nil }
  let(:project_fields) do
    query_nodes(:cluster_agents, cluster_agents_fields, args: { first: first }, max_depth: 3)
  end

  let(:query) do
    args = { full_path: project.full_path }

    with_signature([first], graphql_query_for(:project, args, project_fields))
  end

  before do
    allow(Gitlab::Kas::Client).to receive(:new).and_return(double(get_connected_agents_by_agent_ids: []))
  end

  it 'can retrieve cluster agents' do
    post_graphql(query, current_user: current_user)

    expect(graphql_data_at(:project, :cluster_agents, :nodes)).to match_array(
      agents.map { |agent| a_graphql_entity_for(agent) }
    )
  end

  context 'selecting page info' do
    let(:project_fields) do
      query_nodes(:cluster_agents, args: { first: first }, include_pagination_info: true)
    end

    it 'can paginate cluster agents' do
      post_graphql(query, current_user: current_user, variables: first.with(2))

      expect(graphql_data_at(:project, :cluster_agents, :page_info)).to include(
        'hasNextPage' => be_truthy,
        'hasPreviousPage' => be_falsey
      )
      expect(graphql_data_at(:project, :cluster_agents, :nodes)).to have_attributes(size: 2)
    end
  end

  context 'selecting tokens' do
    let_it_be(:token_1) { create(:cluster_agent_token, agent: agents.second) }
    let_it_be(:token_2) { create(:cluster_agent_token, agent: agents.second, last_used_at: 3.days.ago) }
    let_it_be(:token_3) { create(:cluster_agent_token, agent: agents.second, last_used_at: 2.days.ago) }
    let_it_be(:revoked_token) { create(:cluster_agent_token, :revoked, agent: agents.second) }

    let(:cluster_agents_fields) { [:id, query_nodes(:tokens, of: 'ClusterAgentToken')] }

    it 'can select active tokens in last_used_at order' do
      post_graphql(query, current_user: current_user)

      tokens = graphql_data_at(:project, :cluster_agents, :nodes, :tokens, :nodes)

      expect(tokens).to match(
        [
          a_graphql_entity_for(token_3),
          a_graphql_entity_for(token_2),
          a_graphql_entity_for(token_1)
        ])
    end

    it 'does not suffer from N+1 performance issues' do
      post_graphql(query, current_user: current_user)

      expect do
        post_graphql(query, current_user: current_user)
      end.to issue_same_number_of_queries_as { post_graphql(query, current_user: current_user, variables: [first.with(1)]) }
    end
  end

  context 'selecting connections' do
    let(:agent_meta) { double(version: '1', commit_id: 'abc', pod_namespace: 'namespace', pod_name: 'pod') }
    let(:agent_warning) { double(version: { message: 'Warning message', type: 'warning_type' }) }
    let(:connected_agent) { double(agent_id: agents.first.id, connected_at: 123456, connection_id: 1, agent_meta: agent_meta, warnings: [agent_warning]) }

    let(:metadata_fields) { query_graphql_field(:metadata, {}, [:version, :commit, :pod_namespace, :pod_name], 'AgentMetadata') }
    let(:version_warning_fields) { query_graphql_field(:version, {}, [:message, :type], 'AgentVersionWarning') }
    let(:warnings_fields) { query_graphql_field(:warnings, {}, [version_warning_fields], 'AgentWarning') }
    let(:cluster_agents_fields) { [:id, query_nodes(:connections, [:connection_id, :connected_at, metadata_fields, warnings_fields])] }

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_return(double(get_connected_agents_by_agent_ids: [connected_agent]))
    end

    it 'can retrieve connections and agent metadata' do
      post_graphql(query, current_user: current_user)

      connection = graphql_data_at(:project, :cluster_agents, :nodes, :connections, :nodes).first

      expect(connection).to include({
        'connectionId' => connected_agent.connection_id.to_s,
        'connectedAt' => Time.at(connected_agent.connected_at),
        'metadata' => {
          'version' => agent_meta.version,
          'commit' => agent_meta.commit_id,
          'podNamespace' => agent_meta.pod_namespace,
          'podName' => agent_meta.pod_name
        },
        'warnings' => [
          { 'version' => {
            'message' => agent_warning.version[:message],
            'type' => agent_warning.version[:type]
          } }
        ]
      })
    end
  end

  context 'selecting activity events' do
    let_it_be(:token) { create(:cluster_agent_token, agent: agents.first) }
    let_it_be(:event) { create(:agent_activity_event, agent: agents.first, agent_token: token, user: current_user) }

    let(:cluster_agents_fields) { [:id, query_nodes(:activity_events, of: 'ClusterAgentActivityEvent', max_depth: 2)] }

    it 'retrieves activity event details' do
      post_graphql(query, current_user: current_user)

      response = graphql_data_at(:project, :cluster_agents, :nodes, :activity_events, :nodes).first

      expect(response).to include({
        'kind' => event.kind,
        'level' => event.level,
        'recordedAt' => event.recorded_at.iso8601,
        'agentToken' => hash_including('name' => token.name),
        'user' => hash_including('name' => current_user.name)
      })
    end

    it 'preloads associations to prevent N+1 queries' do
      user = create(:user)
      token = create(:cluster_agent_token, agent: agents.second)
      create(:agent_activity_event, agent: agents.second, agent_token: token, user: user)

      post_graphql(query, current_user: current_user)

      expect do
        post_graphql(query, current_user: current_user)
      end.to issue_same_number_of_queries_as { post_graphql(query, current_user: current_user, variables: [first.with(1)]) }
    end
  end
end
