# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::RefreshService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:root_ancestor) { create(:group) }

    let_it_be(:removed_group) { create(:group, parent: root_ancestor) }
    let_it_be(:modified_group) { create(:group, parent: root_ancestor) }
    let_it_be(:added_group) { create(:group, path: 'group-path-with-UPPERCASE', parent: root_ancestor) }

    let_it_be(:removed_project) { create(:project, namespace: root_ancestor) }
    let_it_be(:modified_project) { create(:project, namespace: root_ancestor) }
    let_it_be(:added_project) { create(:project, path: 'project-path-with-UPPERCASE', namespace: root_ancestor) }

    let(:project) { create(:project, namespace: root_ancestor) }
    let(:agent) { create(:cluster_agent, project: project) }

    let(:config) do
      {
        ci_access: {
          groups: [
            { id: added_group.full_path, default_namespace: 'default' },
            # Uppercase path verifies case-insensitive matching.
            { id: modified_group.full_path.upcase, default_namespace: 'new-namespace', protected_branches_only: 'true' }
          ],
          projects: [
            { id: added_project.full_path, default_namespace: 'default' },
            # Uppercase path verifies case-insensitive matching.
            { id: modified_project.full_path.upcase, default_namespace: 'new-namespace',
              protected_branches_only: 'true' }
          ]
        }
      }.deep_stringify_keys
    end

    subject { described_class.new(agent, config: config).execute }

    before do
      default_config = { default_namespace: 'default' }

      agent.ci_access_group_authorizations.create!(group: removed_group, config: default_config)
      agent.ci_access_group_authorizations.create!(group: modified_group, config: default_config)

      agent.ci_access_project_authorizations.create!(project: removed_project, config: default_config)
      agent.ci_access_project_authorizations.create!(project: modified_project, config: default_config)
    end

    shared_examples 'removing authorization' do
      context 'config contains no groups' do
        let(:config) { {} }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end

      context 'config contains groups outside of the configuration project hierarchy' do
        let(:project) { create(:project, namespace: create(:group)) }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end

      context 'configuration project does not belong to a group' do
        let(:project) { create(:project) }

        it 'removes all authorizations' do
          expect(subject).to be_truthy
          expect(authorizations).to be_empty
        end
      end
    end

    describe 'group authorization' do
      it 'refreshes authorizations for the agent' do
        expect(subject).to be_truthy
        expect(agent.ci_access_authorized_groups).to contain_exactly(added_group, modified_group)

        added_authorization = agent.ci_access_group_authorizations.find_by(group: added_group)
        expect(added_authorization.config).to eq({ 'default_namespace' => 'default' })

        modified_authorization = agent.ci_access_group_authorizations.find_by(group: modified_group)
        expect(modified_authorization.config).to eq({ 'default_namespace' => 'new-namespace',
                                                      'protected_branches_only' => 'true' })
      end

      context 'config contains too many groups' do
        before do
          stub_const("#{described_class}::AUTHORIZED_ENTITY_LIMIT", 1)
        end

        it 'authorizes groups up to the limit' do
          expect(subject).to be_truthy
          expect(agent.ci_access_authorized_groups).to contain_exactly(added_group)
        end
      end

      include_examples 'removing authorization' do
        let(:authorizations) { agent.ci_access_authorized_groups }
      end
    end

    describe 'project authorization' do
      it 'refreshes authorizations for the agent' do
        expect(subject).to be_truthy
        expect(agent.ci_access_authorized_projects).to contain_exactly(added_project, modified_project)

        added_authorization = agent.ci_access_project_authorizations.find_by(project: added_project)
        expect(added_authorization.config).to eq({ 'default_namespace' => 'default' })

        modified_authorization = agent.ci_access_project_authorizations.find_by(project: modified_project)
        expect(modified_authorization.config).to eq({ 'default_namespace' => 'new-namespace',
                                                      'protected_branches_only' => 'true' })
      end

      context 'project does not belong to a group, and is in the same namespace as the agent' do
        let(:root_ancestor) { create(:namespace) }
        let(:added_project) { create(:project, namespace: root_ancestor) }

        it 'creates an authorization record for the project' do
          expect(subject).to be_truthy
          expect(agent.ci_access_authorized_projects).to contain_exactly(added_project)
        end
      end

      context 'project does not belong to a group, and is authorizing itself' do
        let(:root_ancestor) { create(:namespace) }
        let(:added_project) { project }

        it 'creates an authorization record for the project' do
          expect(subject).to be_truthy
          expect(agent.ci_access_authorized_projects).to contain_exactly(added_project)
        end
      end

      context 'config contains too many projects' do
        before do
          stub_const("#{described_class}::AUTHORIZED_ENTITY_LIMIT", 1)
        end

        it 'authorizes projects up to the limit' do
          expect(subject).to be_truthy
          expect(agent.ci_access_authorized_projects).to contain_exactly(added_project)
        end
      end

      include_examples 'removing authorization' do
        let(:authorizations) { agent.ci_access_authorized_projects }
      end
    end
  end
end
