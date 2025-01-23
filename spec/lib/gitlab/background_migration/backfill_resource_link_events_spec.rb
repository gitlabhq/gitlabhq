# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillResourceLinkEvents, feature_category: :team_planning do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:system_note_metadata) { table(:system_note_metadata) }
  let(:resource_link_events) { table(:resource_link_events) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:work_item_issue_type_id) { table(:work_item_types).find_by(name: 'Issue').id }
  let(:work_item_task_type_id) { table(:work_item_types).find_by(name: 'Task').id }

  # rubocop:disable Layout/LineLength -- existing file
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) { namespaces.create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let!(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id) }
  let!(:issue) { issues.create!(iid: 100, project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: work_item_issue_type_id) }
  let!(:work_item) { issues.create!(iid: 200, project_id: project.id, namespace_id: project.project_namespace_id, work_item_type_id: work_item_task_type_id) }
  let!(:user) { users.create!(name: 'user', projects_limit: 10) }

  # Given a system note generated for a child work item, "Added #100 as parent issue",
  # the migration searches for the parent issue with iid #100 using the child work item's project scope.
  # Creating antoher issue that has the identical iid under another project ensures the migration is picking up the correct issue.
  let!(:other_namespace) { namespaces.create!(name: "other_namespace", path: "other_namespace", organization_id: organization.id) }
  let!(:other_project) { projects.create!(namespace_id: other_namespace.id, project_namespace_id: other_namespace.id, organization_id: organization.id) }
  let!(:other_issue) { issues.create!(iid: issue.iid, project_id: other_project.id, namespace_id: other_project.project_namespace_id, work_item_type_id: work_item_issue_type_id) }
  let!(:other_work_item) { issues.create!(iid: 200, project_id: other_project.id, namespace_id: other_project.project_namespace_id, work_item_type_id: work_item_task_type_id) }
  # rubocop:enable Layout/LineLength

  subject(:migration) do
    described_class.new(
      start_id: system_note_metadata.minimum(:id),
      end_id: system_note_metadata.maximum(:id),
      batch_table: :system_note_metadata,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  describe '#perform' do
    it 'does nothing when relevant notes do not exist' do
      expect { migration.perform }
        .to not_change { resource_link_events.count }
    end

    shared_examples 'a resource_link_event is correctly created' do
      it "correctly backfills a resource_link_event record", :aggregate_failures do
        expect { migration.perform }
          .to change { resource_link_events.count }.from(0).to(1)

        expect(resource_link_events.last.attributes).to match(a_hash_including(expected_attributes))
        expect(resource_link_events.last.created_at).to be_like_time(system_note.created_at)
      end
    end

    context "for 'relate_to_parent' system_note_metadata record" do
      let!(:system_note) do
        create_relate_to_parent_note(parent: issue, child: work_item, issue_type_name: issue_type_name)
      end

      let(:expected_attributes) do
        {
          "action" => described_class::ResourceLinkEvent.actions[:add],
          "user_id" => user.id,
          "issue_id" => issue.id,
          "child_work_item_id" => work_item.id,
          "system_note_metadata_id" => system_note.id
        }
      end

      context 'when issue_type_name is `issue`' do
        let(:issue_type_name) { 'issue' }

        it_behaves_like 'a resource_link_event is correctly created'
      end

      context "when issue_type_name is not `issue`" do
        let(:issue_type_name) { 'objective' }

        it_behaves_like 'a resource_link_event is correctly created'
      end
    end

    context "for 'unrelate_to_parent' system_note_metadata record" do
      let!(:system_note) do
        create_unrelate_from_parent_note(parent: issue, child: work_item, issue_type_name: issue_type_name)
      end

      let(:expected_attributes) do
        {
          "action" => described_class::ResourceLinkEvent.actions[:remove],
          "user_id" => user.id,
          "issue_id" => issue.id,
          "child_work_item_id" => work_item.id,
          "system_note_metadata_id" => system_note.id
        }
      end

      context 'when issue_type_name is `issue`' do
        let(:issue_type_name) { 'issue' }

        it_behaves_like 'a resource_link_event is correctly created'
      end

      context "when issue_type_name is not `issue`" do
        let(:issue_type_name) { 'objective' }

        it_behaves_like 'a resource_link_event is correctly created'
      end
    end

    context "when a backfilled note exists" do
      let!(:backfilled_system_note) do
        create_relate_to_parent_note(parent: other_issue, child: other_work_item, issue_type_name: 'issue')
      end

      let!(:backfilled_resource_link_event) do
        resource_link_events.create!(
          action: described_class::ResourceLinkEvent.actions[:add],
          user_id: user.id,
          issue_id: other_issue.id,
          child_work_item_id: other_work_item.id,
          created_at: backfilled_system_note.created_at,
          system_note_metadata_id: backfilled_system_note.id)
      end

      before do
        # Create two system notes for which resource_link_events should be created (backfilled)
        create_relate_to_parent_note(parent: issue, child: work_item, issue_type_name: 'issue')
        create_unrelate_from_parent_note(parent: issue, child: work_item, issue_type_name: 'objective')

        # A backfilled resource_link_event exists for `backfilled_system_note`
        # No resource_link_event record should be created for `backfilled_system_note`
        # To test, update `backfilled_system_note` and check `backfilled_resource_link_event` does not change
        backfilled_system_note.update!(created_at: 1.week.ago)
      end

      it "correctly backfills the system notes without those that have been backfilled" do
        expect { migration.perform }
          .to change { resource_link_events.count }.from(1).to(3)
          .and not_change { backfilled_resource_link_event }
      end
    end

    context 'with unexpected note content' do
      context 'when note iid is prefixed' do
        before do
          note = notes.create!(
            noteable_type: 'Issue',
            noteable_id: work_item.id,
            author_id: user.id,
            # Cross-project linking is not supported currently.
            # When an issue is referenced not in its own project,
            # the iid is prefixed by the project name like gitlab#1
            # Test the scenario to ensure no resource_link_event is wrongly created.
            note: "added gitlab##{issue.iid} as parent issue"
          )

          system_note_metadata.create!(action: 'relate_to_parent', note_id: note.id)
        end

        it 'does not create resource_link_events record' do
          expect { migration.perform }
            .to not_change { resource_link_events.count }
        end
      end
    end
  end

  def create_relate_to_parent_note(parent:, child:, issue_type_name:)
    note = notes.create!(
      noteable_type: 'Issue',
      noteable_id: child.id,
      author_id: user.id,
      note: "added ##{parent.iid} as parent #{issue_type_name}"
    )

    system_note_metadata.create!(action: 'relate_to_parent', note_id: note.id)
  end

  def create_unrelate_from_parent_note(parent:, child:, issue_type_name:)
    note = notes.create!(
      noteable_type: 'Issue',
      noteable_id: child.id,
      author_id: user.id,
      note: "removed parent #{issue_type_name} ##{parent.iid}"
    )

    system_note_metadata.create!(action: 'unrelate_from_parent', note_id: note.id)
  end
end
