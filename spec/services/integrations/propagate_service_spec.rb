# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::PropagateService, feature_category: :integrations do
  describe '#execute' do
    include JiraIntegrationHelpers

    before do
      stub_jira_integration_test
    end

    let(:group) { create(:group) }

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
      let(:another_project) { create(:project) }

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
      let(:group_integration) { create(:jira_integration, :group, group: group) }

      context 'with a project without integration' do
        let(:another_project) { create(:project, group: group) }

        it 'calls to PropagateIntegrationProjectWorker' do
          expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
            .with(group_integration.id, another_project.id, another_project.id)

          described_class.new(group_integration).execute
        end
      end

      context 'with a subgroup without integration' do
        let(:subgroup) { create(:group, parent: group) }

        it 'calls to PropagateIntegrationGroupWorker' do
          expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
            .with(group_integration.id, subgroup.id, subgroup.id)

          described_class.new(group_integration).execute
        end
      end

      context 'and the integration is instance specific' do
        let(:group_integration) { create(:beyond_identity_integration, :group, group: group, instance: false) }

        context 'with a subgroup with integration' do
          let(:subgroup) { create(:group, parent: group) }
          let(:subgroup_integration) do
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
        let(:subgroup) { create(:group, parent: group) }
        let(:subgroup_integration) { create(:jira_integration, :group, group: subgroup, inherit_from_id: group_integration.id) }

        it 'calls to PropagateIntegrationInheritDescendantWorker' do
          expect(PropagateIntegrationInheritDescendantWorker).to receive(:perform_async)
            .with(group_integration.id, subgroup_integration.id, subgroup_integration.id)

          described_class.new(group_integration).execute
        end
      end
    end
  end
end
