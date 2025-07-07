# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Exclusions::CreateService, feature_category: :source_code_management do
  let(:integration_name) { 'beyond_identity' }
  let_it_be(:admin_user) { create(:admin) }
  let(:current_user) { admin_user }
  let_it_be(:project) { create(:project, :in_subgroup) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let(:projects) { [project] }
  let(:groups) { [group] }
  let(:service) do
    described_class.new(current_user: current_user, integration_name: integration_name, projects: projects,
      groups: groups)
  end

  describe '#execute', :enable_admin_mode do
    subject(:execute) { service.execute }

    it_behaves_like 'performs exclusions service validations'

    context 'when called with too many projects' do
      before do
        stub_const('Integrations::Exclusions::CreateService::MAX_PROJECTS', 0)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('project limit exceeded')
      end
    end

    context 'when called with too many groups' do
      before do
        stub_const('Integrations::Exclusions::CreateService::MAX_GROUPS', 0)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('group limit exceeded')
      end
    end

    it 'creates custom settings' do
      expect { execute }.to change { Integration.count }.by(2)

      group_integration, project_integration = execute.payload
      expect(PropagateIntegrationWorker.jobs).to contain_exactly(
        a_hash_including('args' => [group_integration.id])
      )
      expect(group_integration.active).to be_falsey
      expect(group_integration.inherit_from_id).to be_nil
      expect(project_integration.active).to be_falsey
      expect(project_integration.inherit_from_id).to be_nil
    end

    context 'when there are no projects or groups passed' do
      let(:projects) { [] }
      let(:groups) { [] }

      it 'returns success response' do
        expect(execute).to be_success
        expect(execute.payload).to eq([])
      end
    end

    context 'when there are existing custom settings' do
      let_it_be(:instance_level_integration) { create(:beyond_identity_integration) }
      let_it_be(:project_level_integration) do
        create(
          :beyond_identity_integration,
          active: true,
          project: other_project,
          instance: false,
          inherit_from_id: instance_level_integration.id
        )
      end

      let_it_be(:group_level_integration) do
        create(
          :beyond_identity_integration,
          active: true,
          group: other_group,
          instance: false,
          inherit_from_id: instance_level_integration.id
        )
      end

      let_it_be(:previously_excluded_group) { create(:group) }
      let_it_be(:excluded_group_integration) do
        create(
          :beyond_identity_integration,
          active: false,
          group: previously_excluded_group,
          instance: false,
          inherit_from_id: nil
        )
      end

      let(:expected_group_integration) do
        Integrations::BeyondIdentity.find_by!(group: group, inherit_from_id: nil, active: false)
      end

      let(:expected_project_integration) do
        Integrations::BeyondIdentity.find_by!(project: project, inherit_from_id: nil, active: false)
      end

      let(:projects) { [project, other_project] }
      let(:groups) { [group, other_group] }

      it 'creates exclusions and updates existing ones' do
        expect { execute }.to change { project_level_integration.reload.active }.from(true).to(false)
          .and change { group_level_integration.reload.active }.from(true).to(false)
          .and change { project_level_integration.inherit_from_id }.from(instance_level_integration.id).to(nil)
          .and change { group_level_integration.inherit_from_id }.from(instance_level_integration.id).to(nil)
        expect(PropagateIntegrationWorker.jobs).to contain_exactly(
          a_hash_including('args' => [expected_group_integration.id]),
          a_hash_including('args' => [group_level_integration.id])
        )
      end

      it 'returns the exclusions' do
        expect(execute.payload).to contain_exactly(
          group_level_integration,
          project_level_integration,
          expected_group_integration,
          expected_project_integration
        )
      end

      context 'when there are existing exclusions' do
        let(:groups) { [previously_excluded_group] }
        let(:projects) { [] }

        it 'does not propagate existing' do
          result = execute

          expect(result.payload).to be_blank
          expect(PropagateIntegrationWorker.jobs).to be_blank
        end
      end
    end

    context 'when there are ancestor exclusions' do
      let!(:ancestor_exclusion) do
        create(:beyond_identity_integration, active: false, instance: false, inherit_from_id: nil,
          group: project.root_namespace)
      end

      let(:group_covered_by_ancestor_exclusion) { create(:group, parent: project.parent) }
      let(:project_covered_by_ancestor_exclusion) { project }

      let(:projects) { [project_covered_by_ancestor_exclusion, other_project] }
      let(:groups) { [group_covered_by_ancestor_exclusion, other_group] }

      it 'only creates exclusions for groups and projects not covered by ancestors with exclusions' do
        expect { execute }.to change { Integration.count }.by(2)
        group_integration, project_integration = execute.payload
        expect(group_integration.group_id).to eq(other_group.id)
        expect(project_integration.project_id).to eq(other_project.id)

        expect(group_integration.active).to be_falsey
        expect(group_integration.inherit_from_id).to be_nil
        expect(project_integration.active).to be_falsey
        expect(project_integration.inherit_from_id).to be_nil
      end
    end

    context 'when projects and groups are descendants of another group' do
      let(:projects) { [project] }
      let(:groups) { [project.parent, project.root_namespace] }

      it 'only creates exclusions for groups and projects not covered by ancestors' do
        expect { execute }.to change { Integration.count }.by(1)
        created_integration = execute.payload.first
        expect(PropagateIntegrationWorker.jobs).to contain_exactly(a_hash_including('args' => [created_integration.id]))
        expect(created_integration.group_id).to eq(project.root_namespace.id)
        expect(created_integration.active).to be_falsey
        expect(created_integration.inherit_from_id).to be_nil
      end
    end
  end
end
