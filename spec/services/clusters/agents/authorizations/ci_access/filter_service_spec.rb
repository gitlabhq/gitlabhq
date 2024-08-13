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

    let(:filter_params) { { protected_ref: true } }

    subject(:execute_filter) { described_class.new(agent_authorizations, filter_params, project).execute }

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
            environments: ['staging', 'review/*', 'production'],
            protected_branches_only: false
          ),
          build(
            :agent_ci_access_group_authorization,
            group: group,
            agent: build(:cluster_agent, project: project),
            environments: ['staging', 'review/*', 'production'],
            protected_branches_only: false
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

      let(:agent_authorizations_with_env_and_protected_branches) do
        [
          build(
            :agent_ci_access_project_authorization,
            project: project,
            agent: build(:cluster_agent, project: project),
            environments: ['staging', 'review/*', 'production'],
            protected_branches_only: true
          ),
          build(
            :agent_ci_access_group_authorization,
            group: group,
            agent: build(:cluster_agent, project: project),
            environments: ['staging', 'review/*', 'production'],
            protected_branches_only: true
          )
        ]
      end

      let(:agent_authorizations) do
        (
          agent_authorizations_without_env +
          agent_authorizations_with_env +
          agent_authorizations_with_different_env +
          agent_authorizations_with_env_and_protected_branches
        )
      end

      let(:filter_params) { { environment: 'production', protected_ref: false } }

      it 'returns the authorizations with the given environment AND authorizations without any environment' do
        expected_authorizations = agent_authorizations_with_env + agent_authorizations_without_env

        expect(execute_filter).to match_array expected_authorizations
      end

      context 'when environment filter has a wildcard' do
        let(:filter_params) { { environment: 'review/123', protected_ref: false } }

        it 'returns the authorizations with matching environments AND authorizations without any environment' do
          expected_authorizations = agent_authorizations_with_env + agent_authorizations_without_env

          expect(execute_filter).to match_array expected_authorizations
        end
      end

      context 'when environment filter is nil' do
        let(:filter_params) { { environment: nil, protected_ref: false } }

        it 'returns the authorizations without any environment' do
          expect(execute_filter).to match_array agent_authorizations_without_env
        end
      end

      context 'when executed on protected branch' do
        let(:filter_params) { { environment: 'production', protected_ref: true } }

        it 'returns the authorizations with the given environment AND authorizations without any environment AND the authorizations with protected branches' do
          expected_authorizations = agent_authorizations_with_env + agent_authorizations_without_env + agent_authorizations_with_env_and_protected_branches

          expect(execute_filter).to match_array expected_authorizations
        end
      end
    end

    context 'when filtering protected branches' do
      let(:agent_authorizations_with_protected_agent) do
        build(
          :agent_ci_access_project_authorization,
          project: project,
          agent: build(:cluster_agent, project: project),
          protected_branches_only: protected
        )
      end

      let(:agent_authorizations) { [agent_authorizations_with_protected_agent] }

      context 'with protected agent' do
        let(:protected) { true }

        context 'on protected branch' do
          let(:filter_params) { { protected_ref: true } }

          it 'does return the authorizations as is' do
            expect(execute_filter).to match_array agent_authorizations_with_protected_agent
          end
        end

        context 'on unprotected branch' do
          let(:filter_params) { { protected_ref: false } }

          it 'does not return any authorizations' do
            expect(execute_filter).to eq []
          end

          context 'when kubernetes_agent_protected_branches is disabled' do
            before do
              stub_feature_flags(kubernetes_agent_protected_branches: false)
            end

            it 'does not filter for protected_ref' do
              expect(execute_filter).to match_array agent_authorizations_with_protected_agent
            end
          end
        end
      end

      context 'with unprotected agent' do
        let(:protected) { false }

        context 'on protected branch' do
          let(:filter_params) { { protected_ref: true } }

          it 'does return the authorizations as is' do
            expect(execute_filter).to match_array agent_authorizations_with_protected_agent
          end
        end

        context 'on unprotected branch' do
          let(:filter_params) { { protected_ref: false } }

          it 'does return the authorizations as is' do
            expect(execute_filter).to match_array agent_authorizations_with_protected_agent
          end
        end
      end
    end
  end
end
