# frozen_string_literal: true

RSpec.shared_context 'with reassign placeholder user records' do
  let_it_be(:namespace) { create(:group) }
  let_it_be_with_reload(:import_user) { create(:user, :import_user) }

  let_it_be(:reassigned_by_user) { create(:user, email: "user1@gitlab.com") }
  let_it_be(:reassign_to_user) { create(:user, email: "user2@gitlab.com") }
  let_it_be_with_reload(:source_user) do
    create(:import_source_user,
      :reassignment_in_progress,
      placeholder_user: import_user,
      reassigned_by_user: reassigned_by_user,
      reassign_to_user: reassign_to_user,
      namespace: namespace
    )
  end

  let_it_be_with_reload(:other_source_user) do
    create(:import_source_user,
      :with_reassigned_by_user,
      :reassignment_in_progress,
      namespace: namespace
    )
  end

  let_it_be(:placeholder_user_id) { source_user.placeholder_user_id }
  let_it_be(:other_placeholder_user_id) { other_source_user.placeholder_user_id }

  # MergeRequests
  let_it_be_with_reload(:merge_requests) { create_list(:merge_request, 3, author_id: placeholder_user_id) }

  let_it_be_with_reload(:other_merge_request) do
    create(:merge_request, author_id: other_placeholder_user_id)
  end

  # Approvals
  let_it_be_with_reload(:merge_request_approval) do
    create(:approval, merge_request: other_merge_request, user_id: placeholder_user_id)
  end

  let_it_be_with_reload(:merge_request_approval_2) do
    create(:approval, merge_request: merge_requests[0], user_id: placeholder_user_id)
  end

  let_it_be_with_reload(:other_merge_request_approval) do
    create(:approval, merge_request: merge_requests[0], user_id: other_placeholder_user_id)
  end

  # Issues
  let_it_be_with_reload(:issue) { create(:issue, author_id: placeholder_user_id, closed_by_id: placeholder_user_id) }
  let_it_be_with_reload(:issue_closed) { create(:issue, closed_by_id: placeholder_user_id) }

  # IssueAssignees
  let_it_be_with_reload(:issue_assignee) do
    issue.issue_assignees.create!(user_id: placeholder_user_id, issue_id: issue.id)
  end

  # Notes
  let_it_be_with_reload(:authored_note) { create(:note, author_id: placeholder_user_id) }
  let_it_be_with_reload(:updated_note) { create(:note, updated_by_id: placeholder_user_id) }

  # Groups and projects for membership
  let_it_be_with_refind(:subgroup) { create(:group, parent: namespace) }
  let_it_be_with_refind(:project) { create(:project, group: namespace) }

  # Ci::Builds - schema is gitlab_ci
  let_it_be_with_reload(:ci_build) { create(:ci_build, user_id: placeholder_user_id) }

  let_it_be(:today) { Date.current }

  let_it_be(:project_bot) { create(:user, :project_bot, bot_namespace: project.namespace) }

  subject(:service) { described_class.new(source_user) }

  before_all do
    # Create import_source_user_placeholder_reference for memoized records
    # MergeRequests
    merge_requests.each { |mr| create_placeholder_reference(source_user, mr, user_column: 'author_id') }
    create_placeholder_reference(other_source_user, other_merge_request, user_column: 'author_id')

    # Approvals
    create_placeholder_reference(source_user, merge_request_approval, user_column: 'user_id')
    create_placeholder_reference(source_user, merge_request_approval_2, user_column: 'user_id')
    create_placeholder_reference(other_source_user, other_merge_request_approval, user_column: 'user_id')

    # Issues
    create_placeholder_reference(source_user, issue, user_column: 'author_id')
    create_placeholder_reference(source_user, issue, user_column: 'closed_by_id')
    create_placeholder_reference(source_user, issue_closed, user_column: 'closed_by_id')

    # IssueAssignees
    create_placeholder_reference(
      source_user,
      issue.issue_assignees.find_by(user_id: placeholder_user_id),
      user_column: 'user_id',
      composite_key: { user_id: placeholder_user_id, issue_id: issue.id }
    )

    # Notes
    create_placeholder_reference(source_user, authored_note, user_column: 'author_id')
    create_placeholder_reference(source_user, updated_note, user_column: 'updated_by_id')

    # Member placeholder references
    create(:import_placeholder_membership, :for_group,
      source_user: source_user,
      group: subgroup,
      access_level: Gitlab::Access::REPORTER)
    create(:import_placeholder_membership,
      source_user: source_user,
      project: project,
      access_level: Gitlab::Access::DEVELOPER,
      expires_at: today + 1.day
    )
    create(:import_placeholder_membership, :for_group, source_user: other_source_user, group: subgroup)
    create(:import_placeholder_membership, source_user: other_source_user, project: project)

    # Ci::Builds
    create_placeholder_reference(source_user, ci_build, user_column: 'user_id')
  end

  before do
    # Decrease the sleep in these tests, so the test suite runs faster.
    stub_const("#{described_class}::RELATION_BATCH_SLEEP", 0.01)
  end

  def create_placeholder_reference(source_user, object, user_column:, composite_key: nil)
    numeric_key = object.id if composite_key.nil?

    create(
      :import_source_user_placeholder_reference,
      source_user: source_user,
      model: object.class.name,
      user_reference_column: user_column,
      numeric_key: numeric_key,
      composite_key: composite_key
    )
  end

  shared_examples 'a successful reassignment' do
    it 'completes the reassignment' do
      expect { service.execute }
        .to trigger_internal_events('complete_placeholder_user_reassignment')
        .with(
          namespace: namespace,
          additional_properties: {
            label: Gitlab::GlobalAnonymousId.user_id(source_user.placeholder_user),
            property: Gitlab::GlobalAnonymousId.user_id(source_user.reassign_to_user),
            import_type: source_user.import_type
          }
        )

      expect(source_user.reload).to be_completed
    end

    it 'does not update any records that do not belong to the source user' do
      expect { service.execute }.to not_change { other_merge_request.reload.author_id }
        .from(other_placeholder_user_id)
        .and not_change { other_merge_request_approval.reload.user_id }.from(other_placeholder_user_id)
        .and not_change { other_source_user.reassign_to_user.groups.count }.from(0)
        .and not_change { other_source_user.reassign_to_user.projects.count }.from(0)
    end

    it 'does not delete any placeholder references or memberships that do not belong to the source user' do
      expect { service.execute }
        .to not_change { Import::SourceUserPlaceholderReference.where(source_user: other_source_user).count }.from(2)
        .and not_change { Import::Placeholders::Membership.where(source_user: other_source_user).count }.from(2)
    end
  end

  shared_examples 'reassigns placeholder user records' do
    it 'updates actual records from the source user\'s placeholder reference records' do
      expect { service.execute }.to change { merge_requests[0].reload.author_id }
          .from(placeholder_user_id).to(reassign_user_id)
          .and change { merge_requests[1].reload.author_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { merge_requests[2].reload.author_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { merge_request_approval.reload.user_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { merge_request_approval_2.reload.user_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { issue.reload.author_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { issue.reload.closed_by_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { issue_closed.reload.closed_by_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { authored_note.reload.author_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { updated_note.reload.updated_by_id }.from(placeholder_user_id).to(reassign_user_id)
          .and change { IssueAssignee.where({ user_id: reassign_user_id, issue_id: issue.id }).count }.from(0).to(1)
    end
  end

  shared_examples 'handles membership creation for reassigned users' do
    it 'creates memberships for the reassign user' do
      service.execute

      expect(subgroup.reload.members).to contain_exactly(
        have_attributes(
          user: reassign_user,
          access_level: Gitlab::Access::REPORTER,
          created_by_id: source_user.reassigned_by_user_id,
          expires_at: nil
        )
      )

      expect(project.reload.members).to contain_exactly(
        have_attributes(
          user: reassign_user,
          access_level: Gitlab::Access::DEVELOPER,
          created_by_id: source_user.reassigned_by_user_id,
          expires_at: today + 1.day
        )
      )
    end
  end
end
