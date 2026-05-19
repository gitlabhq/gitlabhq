# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::PropagateService, feature_category: :integrations do
  describe '#execute' do
    include JiraIntegrationHelpers

    before do
      stub_jira_integration_test
    end

    let_it_be(:group) { create(:group) }

    let_it_be(:project) { create(:project) }
    let_it_be(:instance_integration) { create(:jira_integration, :instance) }
    let_it_be(:not_inherited_integration) { create(:jira_integration, project: project) }
    let_it_be(:inherited_integration) do
      create(:jira_integration, project: create(:project), inherit_from_id: instance_integration.id)
    end

    let_it_be(:different_type_inherited_integration) do
      create(:redmine_integration, project: project, inherit_from_id: instance_integration.id)
    end

    context 'with inherited integration' do
      let(:integration) { inherited_integration }

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationInheritWorker).to receive(:perform_async)
          .with(instance_integration.id, inherited_integration.id, inherited_integration.id)

        described_class.new(instance_integration).execute
      end
    end

    context 'with a project without integration' do
      let_it_be(:another_project) { create(:project) }

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
          .with(instance_integration.id, another_project.id, another_project.id)

        described_class.new(instance_integration).execute
      end
    end

    context 'with a group without integration' do
      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
          .with(instance_integration.id, group.id, group.id)

        described_class.new(instance_integration).execute
      end
    end

    context 'for a group-level integration' do
      let_it_be(:group_integration) { create(:jira_integration, :group, group: group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      context 'with a project without integration' do
        let_it_be(:another_project) { create(:project, group: group) }

        it 'calls to PropagateIntegrationProjectWorker' do
          expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
            .with(group_integration.id, another_project.id, another_project.id)

          described_class.new(group_integration).execute
        end
      end

      context 'with a subgroup without integration' do
        it 'calls to PropagateIntegrationGroupWorker' do
          expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
            .with(group_integration.id, subgroup.id, subgroup.id)

          described_class.new(group_integration).execute
        end
      end

      context 'and the integration is instance specific' do
        let_it_be(:group_integration) { create(:beyond_identity_integration, :group, group: group, instance: false) }

        context 'with a subgroup with integration' do
          let_it_be(:subgroup_integration) do
            create(:beyond_identity_integration, :group,
              group: subgroup,
              inherit_from_id: group_integration.id,
              instance: false)
          end

          it 'calls to PropagateIntegrationInheritDescendantWorker' do
            expect(Integrations::PropagateIntegrationDescendantWorker).to receive(:perform_async)
              .with(group_integration.id, subgroup_integration.id, subgroup_integration.id)

            described_class.new(group_integration).execute
          end
        end
      end

      context 'with a subgroup with integration' do
        let_it_be(:subgroup_integration) { create(:jira_integration, :group, group: subgroup, inherit_from_id: group_integration.id) }

        it 'calls to PropagateIntegrationInheritDescendantWorker' do
          expect(PropagateIntegrationInheritDescendantWorker).to receive(:perform_async)
            .with(group_integration.id, subgroup_integration.id, subgroup_integration.id)

          described_class.new(group_integration).execute
        end
      end

      context 'with a project under an archived subgroup' do
        let_it_be(:archived_subgroup) { create(:group, :archived, parent: group) }
        let_it_be(:project_in_archived_subgroup) { create(:project, group: archived_subgroup) }

        it 'excludes projects under archived groups via namespace pluck' do
          expect(PropagateIntegrationProjectWorker).not_to receive(:perform_async)
            .with(group_integration.id, project_in_archived_subgroup.id, anything)

          described_class.new(group_integration).execute
        end
      end

      context 'with a project that already has the integration' do
        let_it_be(:project_with_integration) { create(:project, group: group) }
        let_it_be(:existing_integration) do
          create(:jira_integration, project: project_with_integration)
        end

        it 'includes the project in the batch since the worker re-filters' do
          expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
            .with(group_integration.id, anything, anything).at_least(:once)

          described_class.new(group_integration).execute
        end
      end

      context 'with a descendant group that already has the integration' do
        before do
          create(:jira_integration, :group, group: subgroup)
        end

        it 'includes the group in the batch since the worker re-filters' do
          expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
            .with(group_integration.id, subgroup.id, subgroup.id)

          described_class.new(group_integration).execute
        end
      end

      context 'when there are no descendant groups' do
        let_it_be(:isolated_group) { create(:group) }
        let_it_be(:isolated_integration) { create(:jira_integration, :group, group: isolated_group) }

        it 'does not call PropagateIntegrationGroupWorker' do
          expect(PropagateIntegrationGroupWorker).not_to receive(:perform_async)

          described_class.new(isolated_integration).execute
        end
      end

      context 'when all descendant namespaces are archived' do
        before do
          group.namespace_settings.update!(archived: true)
        end

        it 'does not call PropagateIntegrationProjectWorker for projects' do
          expect(PropagateIntegrationProjectWorker).not_to receive(:perform_async)

          described_class.new(group_integration).execute
        end
      end

      context 'when integration_propagation_simplified_batching is disabled' do
        before do
          stub_feature_flags(integration_propagation_simplified_batching: false)
        end

        context 'for project propagation' do
          let_it_be(:project_in_group) { create(:project, group: group) }

          it 'propagates integration to projects using subquery path' do
            expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
              .with(group_integration.id, project_in_group.id, project_in_group.id)

            described_class.new(group_integration).execute
          end
        end

        context 'for group propagation' do
          it 'propagates integration to descendant groups using subquery path' do
            expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
              .with(group_integration.id, subgroup.id, subgroup.id)

            described_class.new(group_integration).execute
          end
        end
      end
    end
  end
end
