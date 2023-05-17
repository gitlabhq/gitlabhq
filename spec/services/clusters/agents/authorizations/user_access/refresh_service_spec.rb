# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::RefreshService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:root_ancestor) { create(:group) }
    let_it_be(:agent_management_project) { create(:project, namespace: root_ancestor) }
    let_it_be(:group_1) { create(:group, path: 'group-path-with-UPPERCASE', parent: root_ancestor) }
    let_it_be(:group_2) { create(:group, parent: root_ancestor) }
    let_it_be(:project_1) { create(:project, path: 'project-path-with-UPPERCASE', namespace: root_ancestor) }
    let_it_be(:project_2) { create(:project, namespace: root_ancestor) }

    let(:agent) { create(:cluster_agent, project: agent_management_project) }

    let(:config) do
      {
        user_access: {
          groups: [
            { id: group_2.full_path }
          ],
          projects: [
            { id: project_2.full_path }
          ]
        }
      }.deep_merge(extra_config).deep_stringify_keys
    end

    let(:extra_config) { {} }

    subject { described_class.new(agent, config: config).execute }

    before do
      agent.user_access_group_authorizations.create!(group: group_1, config: {})
      agent.user_access_project_authorizations.create!(project: project_1, config: {})
    end

    shared_examples 'removing authorization' do
      context 'when config contains no groups or projects' do
        let(:config) { {} }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end

      context 'when config contains groups or projects outside of the configuration project hierarchy' do
        let_it_be(:agent_management_project) { create(:project, namespace: create(:group)) }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end

      context 'when configuration project does not belong to a group' do
        let_it_be(:agent_management_project) { create(:project) }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end
    end

    describe 'group authorization' do
      it 'refreshes authorizations for the agent' do
        expect(subject).to be_truthy
        expect(agent.user_access_authorized_groups).to contain_exactly(group_2)

        added_authorization = agent.user_access_group_authorizations.find_by(group: group_2)
        expect(added_authorization.config).to eq({})
      end

      context 'when config contains "access_as" keyword' do
        let(:extra_config) do
          {
            user_access: {
              access_as: {
                agent: {}
              }
            }
          }
        end

        it 'refreshes authorizations for the agent' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_groups).to contain_exactly(group_2)

          added_authorization = agent.user_access_group_authorizations.find_by(group: group_2)
          expect(added_authorization.config).to eq({ 'access_as' => { 'agent' => {} } })
        end
      end

      context 'when config contains too many groups' do
        before do
          stub_const("#{described_class}::AUTHORIZED_ENTITY_LIMIT", 0)
        end

        it 'authorizes groups up to the limit' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_groups).to be_empty
        end
      end

      include_examples 'removing authorization' do
        let(:authorizations) { agent.user_access_authorized_groups }
      end
    end

    describe 'project authorization' do
      it 'refreshes authorizations for the agent' do
        expect(subject).to be_truthy
        expect(agent.user_access_authorized_projects).to contain_exactly(project_2)

        added_authorization = agent.user_access_project_authorizations.find_by(project: project_2)
        expect(added_authorization.config).to eq({})
      end

      context 'when config contains "access_as" keyword' do
        let(:extra_config) do
          {
            user_access: {
              access_as: {
                agent: {}
              }
            }
          }
        end

        it 'refreshes authorizations for the agent' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_projects).to contain_exactly(project_2)

          added_authorization = agent.user_access_project_authorizations.find_by(project: project_2)
          expect(added_authorization.config).to eq({ 'access_as' => { 'agent' => {} } })
        end
      end

      context 'when project belongs to a user namespace, and is in the same namespace as the agent' do
        let_it_be(:root_ancestor) { create(:namespace) }
        let_it_be(:agent_management_project) { create(:project, namespace: root_ancestor) }
        let_it_be(:project_1) { create(:project, path: 'project-path-with-UPPERCASE', namespace: root_ancestor) }
        let_it_be(:project_2) { create(:project, namespace: root_ancestor) }

        it 'creates an authorization record for the project' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_projects).to contain_exactly(project_2)
        end
      end

      context 'when project belongs to a user namespace, and is authorizing itself' do
        let_it_be(:root_ancestor) { create(:namespace) }
        let_it_be(:agent_management_project) { create(:project, namespace: root_ancestor) }
        let_it_be(:project_1) { create(:project, path: 'project-path-with-UPPERCASE', namespace: root_ancestor) }
        let_it_be(:project_2) { agent_management_project }

        it 'creates an authorization record for the project' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_projects).to contain_exactly(project_2)
        end
      end

      context 'when config contains too many projects' do
        before do
          stub_const("#{described_class}::AUTHORIZED_ENTITY_LIMIT", 0)
        end

        it 'authorizes projects up to the limit' do
          expect(subject).to be_truthy
          expect(agent.user_access_authorized_projects).to be_empty
        end
      end

      include_examples 'removing authorization' do
        let(:authorizations) { agent.user_access_authorized_projects }
      end
    end
  end
end
