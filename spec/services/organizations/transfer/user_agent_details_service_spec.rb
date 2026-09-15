# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::UserAgentDetailsService, :aggregate_failures,
  feature_category: :instance_resiliency do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }

  let_it_be(:group) { create(:group, organization: old_organization) }
  let_it_be(:subgroup) { create(:group, parent: group, organization: old_organization) }
  let_it_be(:project) { create(:project, namespace: group, organization: old_organization) }
  let_it_be(:nested_project) { create(:project, namespace: subgroup, organization: old_organization) }

  subject(:execute) { run_service }

  def run_service
    described_class.new(
      group: group,
      old_organization: old_organization,
      new_organization: new_organization
    ).execute
  end

  describe '#execute' do
    it 'moves details for issues in the group' do
      detail = create(:user_agent_detail,
        subject: create(:issue, project: project), organization: old_organization)

      expect(detail.subject_type).to eq('Issue')

      execute

      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    it 'moves details for issues in a nested subgroup' do
      detail = create(:user_agent_detail,
        subject: create(:issue, project: nested_project), organization: old_organization)

      execute

      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    # Group-level work items have a NULL project_id, which is why the service scopes by
    # issues.namespace_id rather than project_id.
    it 'moves details for group-level work items' do
      work_item = create(:work_item, :group_level, namespace: subgroup)
      detail = create(:user_agent_detail, subject: work_item, organization: old_organization)

      expect(work_item.project_id).to be_nil
      expect(detail.subject_type).to eq('Issue')

      execute

      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    it 'moves details for several issues in the same namespace' do
      details = create_list(:issue, 3, project: project).map do |issue|
        create(:user_agent_detail, subject: issue, organization: old_organization)
      end

      execute

      expect(details.map { |detail| detail.reload.organization_id }).to all(eq(new_organization.id))
    end

    it 'leaves details for issues outside the group alone' do
      other_group = create(:group, organization: old_organization)
      other_project = create(:project, namespace: other_group, organization: old_organization)
      detail = create(:user_agent_detail,
        subject: create(:issue, project: other_project), organization: old_organization)

      expect { execute }.not_to change { detail.reload.organization_id }
    end

    it 'leaves details belonging to another organization alone' do
      unrelated_organization = create(:organization)
      detail = create(:user_agent_detail,
        subject: create(:issue, project: project), organization: unrelated_organization)

      expect { execute }.not_to change { detail.reload.organization_id }
    end

    it 'moves details for project snippets' do
      detail = create(:user_agent_detail,
        subject: create(:project_snippet, project: project), organization: old_organization)

      expect(detail.subject_type).to eq('Snippet')

      execute

      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    it 'moves details for project snippets in a nested subgroup' do
      detail = create(:user_agent_detail,
        subject: create(:project_snippet, project: nested_project), organization: old_organization)

      execute

      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    # Personal snippets follow their author, not a group, so they belong to
    # Organizations::Transfer::UsersService. Guards the project_id filter against widening to all
    # snippets.
    it 'leaves personal snippet details alone' do
      detail = create(:user_agent_detail,
        subject: create(:personal_snippet, organization: old_organization),
        organization: old_organization)

      expect(detail.subject_type).to eq('Snippet')

      expect { execute }.not_to change { detail.reload.organization_id }
    end

    it 'leaves details for project snippets outside the group alone' do
      other_group = create(:group, organization: old_organization)
      other_project = create(:project, namespace: other_group, organization: old_organization)
      detail = create(:user_agent_detail,
        subject: create(:project_snippet, project: other_project), organization: old_organization)

      expect { execute }.not_to change { detail.reload.organization_id }
    end

    context 'when a project holds more snippets than one batch' do
      let!(:details) do
        create_list(:project_snippet, 3, project: project).map do |snippet|
          create(:user_agent_detail, subject: snippet, organization: old_organization)
        end
      end

      let(:execute_service) { run_service }
      let(:expected_batch_queries) { { 'user_agent_details' => 3 } }

      before do
        stub_const("#{described_class}::SNIPPET_BATCH_SIZE", 1)
      end

      it 'moves details across every batch' do
        execute

        expect(details.map { |detail| detail.reload.organization_id }).to all(eq(new_organization.id))
      end

      it_behaves_like 'generates batched transfer queries'
    end

    it 'is a no-op when run again' do
      detail = create(:user_agent_detail,
        subject: create(:issue, project: project), organization: old_organization)

      run_service

      expect { run_service }.not_to change { detail.reload.organization_id }
      expect(detail.reload.organization_id).to eq(new_organization.id)
    end

    # by_root_id resolves any namespace to its root, so without the root? guard a subgroup would
    # sweep the whole hierarchy including its siblings.
    context 'when given a subgroup instead of a root group' do
      it 'does nothing and logs' do
        detail = create(:user_agent_detail,
          subject: create(:issue, project: nested_project), organization: old_organization)
        sibling_detail = create(:user_agent_detail,
          subject: create(:issue, project: project), organization: old_organization)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(message: 'Skipping user_agent_details transfer: group is not a root group')
        )

        described_class.new(
          group: subgroup,
          old_organization: old_organization,
          new_organization: new_organization
        ).execute

        expect(detail.reload.organization_id).to eq(old_organization.id)
        expect(sibling_detail.reload.organization_id).to eq(old_organization.id)
      end
    end

    it 'does not leak across root groups sharing nothing but the organization' do
      other_root = create(:group, organization: old_organization)
      other_project = create(:project, namespace: other_root, organization: old_organization)
      other_detail = create(:user_agent_detail,
        subject: create(:issue, project: other_project), organization: old_organization)
      own_detail = create(:user_agent_detail,
        subject: create(:issue, project: project), organization: old_organization)

      execute

      expect(own_detail.reload.organization_id).to eq(new_organization.id)
      expect(other_detail.reload.organization_id).to eq(old_organization.id)
    end

    context 'when a namespace holds more issues than one batch' do
      let!(:details) do
        create_list(:issue, 3, project: project).map do |issue|
          create(:user_agent_detail, subject: issue, organization: old_organization)
        end
      end

      let(:execute_service) { run_service }
      let(:expected_batch_queries) { { 'user_agent_details' => 3 } }

      before do
        stub_const("#{described_class}::ISSUE_BATCH_SIZE", 1)
      end

      it 'moves details across every batch' do
        execute

        expect(details.map { |detail| detail.reload.organization_id }).to all(eq(new_organization.id))
      end

      it_behaves_like 'generates batched transfer queries'
    end

    # Group-type and Project-type namespaces are walked in separate passes, so one run has to
    # cover both.
    it 'moves details for both namespace types in a single run' do
      group_level_detail = create(:user_agent_detail,
        subject: create(:work_item, :group_level, namespace: subgroup), organization: old_organization)
      project_level_detail = create(:user_agent_detail,
        subject: create(:issue, project: nested_project), organization: old_organization)

      execute

      expect(group_level_detail.reload.organization_id).to eq(new_organization.id)
      expect(project_level_detail.reload.organization_id).to eq(new_organization.id)
    end
  end
end
