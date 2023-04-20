# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::FilterService, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:agent_authorizations_without_env) do
      [
        build(:agent_ci_access_project_authorization, project: project, agent: build(:cluster_agent, project: project)),
        build(:agent_ci_access_group_authorization, group: group, agent: build(:cluster_agent, project: project)),
        ::Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization.new(agent: build(:cluster_agent, project: project))
      ]
    end

    let(:filter_params) { {} }

    subject(:execute_filter) { described_class.new(agent_authorizations, filter_params).execute }

    context 'when there are no filters' do
      let(:agent_authorizations) { agent_authorizations_without_env }

      it 'returns the authorizations as is' do
        expect(execute_filter).to eq agent_authorizations
      end
    end

    context 'when filtering by environment' do
      let(:agent_authorizations_with_env) do
        [
          build(
            :agent_ci_access_project_authorization,
            project: project,
            agent: build(:cluster_agent, project: project),
            environments: ['staging', 'review/*', 'production']
          ),
          build(
            :agent_ci_access_group_authorization,
            group: group,
            agent: build(:cluster_agent, project: project),
            environments: ['staging', 'review/*', 'production']
          )
        ]
      end

      let(:agent_authorizations_with_different_env) do
        [
          build(
            :agent_ci_access_project_authorization,
            project: project,
            agent: build(:cluster_agent, project: project),
            environments: ['staging']
          ),
          build(
            :agent_ci_access_group_authorization,
            group: group,
            agent: build(:cluster_agent, project: project),
            environments: ['staging']
          )
        ]
      end

      let(:agent_authorizations) do
        (
          agent_authorizations_without_env +
          agent_authorizations_with_env +
          agent_authorizations_with_different_env
        )
      end

      let(:filter_params) { { environment: 'production' } }

      it 'returns the authorizations with the given environment AND authorizations without any environment' do
        expected_authorizations = agent_authorizations_with_env + agent_authorizations_without_env

        expect(execute_filter).to match_array expected_authorizations
      end

      context 'when environment filter has a wildcard' do
        let(:filter_params) { { environment: 'review/123' } }

        it 'returns the authorizations with matching environments AND authorizations without any environment' do
          expected_authorizations = agent_authorizations_with_env + agent_authorizations_without_env

          expect(execute_filter).to match_array expected_authorizations
        end
      end

      context 'when environment filter is nil' do
        let(:filter_params) { { environment: nil } }

        it 'returns the authorizations without any environment' do
          expect(execute_filter).to match_array agent_authorizations_without_env
        end
      end
    end
  end
end
