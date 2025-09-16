# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkItemTransitions, feature_category: :team_planning do
  let(:organizations_table) { table(:organizations) }
  let(:issues_table) { table(:issues) }
  let(:epics_table) { table(:epics) }
  let(:users_table) { table(:users) }
  let(:work_item_transitions_table) { table(:work_item_transitions) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:work_item_types) { table(:work_item_types) }

  let!(:work_item_type) { work_item_types.find_by!(base_type: 0) } # Issue type
  let!(:epic_work_item_type) { work_item_types.find_by!(base_type: 7) } # Epic type

  let!(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let!(:group) do
    table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1', organization_id: organization.id)
  end

  let!(:project_namespace) { namespaces_table.create!(name: 'test', path: 'test', organization_id: organization.id) }
  let!(:project) do
    projects_table.create!(namespace_id: group.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id)
  end

  let!(:user) do
    users_table.create!(name: 'test user', email: 'test@example.com', projects_limit: 1,
      organization_id: organization.id)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: issues_table.minimum(:id),
      end_id: issues_table.maximum(:id),
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    context 'when there are issues with transition data' do
      let!(:moved_to) do
        issues_table.create!(
          title: "Moved to",
          work_item_type_id: work_item_type.id,
          project_id: project.id,
          namespace_id: project_namespace.id
        )
      end

      let!(:duplicated_to) do
        issues_table.create!(
          title: "Duplicated to",
          work_item_type_id: work_item_type.id,
          project_id: project.id,
          namespace_id: project_namespace.id
        )
      end

      let!(:promoted_to_work_item) do
        issues_table.create!(title: "Promoted_to", namespace_id: group.id, work_item_type_id: epic_work_item_type.id)
      end

      let!(:promoted_to) do
        epics_table.create!(
          iid: 1,
          title: "Promoted_to",
          title_html: "Promoted_to",
          group_id: group.id,
          issue_id: promoted_to_work_item.id,
          author_id: user.id
        )
      end

      let!(:issue_with_moved_to) do
        issues_table.create!(
          title: 'Issue 1',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type.id,
          moved_to_id: moved_to.id
        )
      end

      let!(:issue_with_duplicated_to) do
        issues_table.create!(
          title: 'Issue 2',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type.id,
          duplicated_to_id: duplicated_to.id
        )
      end

      let!(:issue_with_promoted_to_epic) do
        issues_table.create!(
          title: 'Issue 3',
          project_id: project.id,
          namespace_id: project_namespace.id,
          work_item_type_id: work_item_type.id,
          promoted_to_epic_id: promoted_to.id
        )
      end

      let!(:issue_without_transitions) do
        issues_table.create!(
          title: 'Issue 5', project_id: project.id, work_item_type_id: work_item_type.id,
          namespace_id: project_namespace.id,
          moved_to_id: moved_to.id, promoted_to_epic_id: promoted_to.id, duplicated_to_id: duplicated_to.id
        )
      end

      before do
        # Since we have a trigger thats creates a work_item_transitions record, we need to destroy it for the spec.
        work_item_transitions_table.find_by!(work_item_id: issue_without_transitions.id).destroy!
      end

      it 'creates work_item_transitions records for all issues' do
        expect { perform_migration }.to change { work_item_transitions_table.count }.from(6).to(7)

        transition = work_item_transitions_table.find_by(work_item_id: issue_with_moved_to.id)
        expect(transition).to be_present
        expect(transition.namespace_id).to eq(project_namespace.id)
        expect(transition.moved_to_id).to eq(moved_to.id)
        expect(transition.duplicated_to_id).to be_nil
        expect(transition.promoted_to_epic_id).to be_nil

        transition = work_item_transitions_table.find_by(work_item_id: issue_with_duplicated_to.id)
        expect(transition).to be_present
        expect(transition.namespace_id).to eq(project_namespace.id)
        expect(transition.moved_to_id).to be_nil
        expect(transition.duplicated_to_id).to eq(duplicated_to.id)
        expect(transition.promoted_to_epic_id).to be_nil

        transition = work_item_transitions_table.find_by(work_item_id: issue_with_promoted_to_epic.id)
        expect(transition).to be_present
        expect(transition.namespace_id).to eq(project_namespace.id)
        expect(transition.moved_to_id).to be_nil
        expect(transition.duplicated_to_id).to be_nil
        expect(transition.promoted_to_epic_id).to eq(promoted_to.id)

        transition = work_item_transitions_table.find_by(work_item_id: issue_without_transitions.id)
        expect(transition).to be_present
        expect(transition.namespace_id).to eq(project_namespace.id)
        expect(transition.moved_to_id).to eq(moved_to.id)
        expect(transition.duplicated_to_id).to eq(duplicated_to.id)
        expect(transition.promoted_to_epic_id).to eq(promoted_to.id)
      end

      it 'skips updates on conflict' do
        work_item_transitions_table.find_by(work_item_id: issue_with_moved_to.id).update!(moved_to_id: nil)

        expect(issue_with_moved_to.moved_to_id).to be_present
        expect(work_item_transitions_table.find_by(work_item_id: issue_with_moved_to.id).moved_to_id).to be_nil

        expect { perform_migration }.to change { work_item_transitions_table.count }.by(1)
        .and not_change {
          work_item_transitions_table.find_by(work_item_id: issue_with_moved_to.id).moved_to_id
        }

        expect do
          described_class.new(
            start_id: issues_table.minimum(:id),
            end_id: issues_table.maximum(:id),
            batch_table: :issues,
            batch_column: :id,
            sub_batch_size: 2,
            pause_ms: 0,
            connection: ActiveRecord::Base.connection
          ).perform
        end.to not_change { work_item_transitions_table.count }
      end
    end
  end
end
