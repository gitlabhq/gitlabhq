# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Tests involve a lot of objects
RSpec.describe Import::ReassignPlaceholderUserRecordsService, feature_category: :importers do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:reassigned_by_user) { create(:user, email: "user1@gitlab.com") }
  let_it_be(:reassign_to_user) { create(:user, email: "user2@gitlab.com") }
  let_it_be_with_reload(:source_user) do
    create(:import_source_user,
      :reassignment_in_progress,
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
  let_it_be(:real_user) { source_user.reassign_to_user }
  let_it_be(:real_user_id) { real_user.id }

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

  let_it_be(:today) { Date.today }

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

  describe '#execute', :aggregate_failures do
    before do
      allow(service).to receive_messages(db_health_check!: nil, db_table_unavailable?: false)
    end

    shared_examples 'a successful reassignment' do
      it 'completes the reassignment' do
        service.execute

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

    context 'when a user can be reassigned without error' do
      it_behaves_like 'a successful reassignment'

      context 'when reassignment throttling is disabled' do
        before do
          stub_feature_flags(reassignment_throttling: false)
          # Decrease the sleep in this test, so the test suite runs faster.
          # TODO: Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/493977
          stub_const("#{described_class}::RELATION_BATCH_SLEEP", 0.01)
        end

        it 'sleeps between processing each model relation batch' do
          expect(Kernel).to receive(:sleep).with(0.01).exactly(8).times

          service.execute
        end
      end

      it 'updates actual records from the source user\'s placeholder reference records' do
        expect { service.execute }.to change { merge_requests[0].reload.author_id }
          .from(placeholder_user_id).to(real_user_id)
          .and change { merge_requests[1].reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { merge_requests[2].reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { merge_request_approval.reload.user_id }.from(placeholder_user_id).to(real_user_id)
          .and change { merge_request_approval_2.reload.user_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue.reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue.reload.closed_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue_closed.reload.closed_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { authored_note.reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { updated_note.reload.updated_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { IssueAssignee.where({ user_id: real_user_id, issue_id: issue.id }).count }.from(0).to(1)
      end

      it 'creates memberships for the real user' do
        service.execute

        expect(subgroup.reload.members).to contain_exactly(
          have_attributes(
            user: real_user,
            access_level: Gitlab::Access::REPORTER,
            created_by_id: source_user.reassigned_by_user_id,
            expires_at: nil
          )
        )

        expect(project.reload.members).to contain_exactly(
          have_attributes(
            user: real_user,
            access_level: Gitlab::Access::DEVELOPER,
            created_by_id: source_user.reassigned_by_user_id,
            expires_at: today + 1.day
          )
        )
      end

      it 'calls UserProjectAccessChangedService' do
        expect_next_instance_of(UserProjectAccessChangedService, reassign_to_user.id) do |service|
          expect(service).to receive(:execute)
        end

        service.execute
      end

      it 'does not call UserProjectAccessChangedService when there are no memberships created' do
        Import::Placeholders::Membership.delete_all

        expect(UserProjectAccessChangedService).not_to receive(:new)

        expect { service.execute }.not_to change { Member.count }
      end

      it 'does not call UserProjectAccessChangedService when only group memberships are created' do
        Import::Placeholders::Membership.where(project: project).delete_all

        expect(UserProjectAccessChangedService).not_to receive(:new)

        expect { service.execute }.to change { GroupMember.count }.by(1)
      end

      it 'deletes reassigned placeholder references and memberships for the source user' do
        expect { service.execute }
          .to change { Import::SourceUserPlaceholderReference.where(source_user: source_user).count }.to(0)
          .and change { Import::Placeholders::Membership.where(source_user: source_user).count }.to(0)
      end

      context 'when reassigned by user no longer exists' do
        before do
          service.instance_variable_set(:@reassigned_by_user, nil)
        end

        it 'can still create memberships' do
          expect { service.execute }.to change { Member.count }
        end

        it 'logs a warning' do
          allow(Import::Framework::Logger).to receive(:warn)
          expect(Import::Framework::Logger).to receive(:warn).with(
            hash_including(
              message: 'Reassigned by user was not found, this may affect membership checks',
              source_user_id: source_user.id
            )
          )

          service.execute
        end
      end

      context 'when saving the membership fails' do
        before do
          allow_next_instance_of(ProjectMember) do |project_member|
            allow(project_member).to receive(:save).and_raise(ActiveRecord::RecordInvalid)
          end
        end

        it 'logs the error, but continues processing other memberships and deletes member references' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
            kind_of(ActiveRecord::RecordInvalid),
            message: 'Unable to create membership',
            placeholder_membership: kind_of(Hash)
          )
          expect { service.execute }
            .to change { Member.count }.by(1)
            .and(change { Import::Placeholders::Membership.where(source_user: source_user).count }.to(0))
        end
      end

      context 'when a project has been transferred out of the root namespace' do
        before_all do
          project.reload.update!(group: create(:group))
        end

        it 'does not create memberships for that project' do
          service.execute

          expect(project.reload.members).to be_empty
        end

        it 'still deletes all member references for the source user' do
          expect { service.execute }
            .to change { Import::Placeholders::Membership.where(source_user: source_user).count }.to(0)
        end
      end

      context 'when a group has been transferred out of the root namespace' do
        before_all do
          subgroup.reload.update!(parent: create(:group))
        end

        it 'does not create memberships for that group' do
          service.execute

          expect(subgroup.reload.members).to be_empty
        end

        it 'still deletes all member references for the source user' do
          expect { service.execute }
            .to change { Import::Placeholders::Membership.where(source_user: source_user).count }.to(0)
        end
      end

      context 'when user has existing lower level INHERITED membership' do
        before_all do
          namespace.add_guest(real_user)
        end

        it 'still creates the project membership' do
          expect { service.execute }.to change { project.reload.members.count }.to(1)
        end

        it 'still creates the group membership' do
          expect { service.execute }.to change { subgroup.reload.members.count }.to(1)
        end
      end

      context 'when user has existing same level INHERITED membership' do
        before_all do
          namespace.add_reporter(real_user)
        end

        it 'still creates the project membership' do
          expect { service.execute }.to change { project.reload.members.count }.to(1)
        end

        it 'still creates the group membership' do
          expect { service.execute }.to change { subgroup.reload.members.count }.to(1)
        end
      end

      context 'when user has existing higher level INHERITED membership' do
        before_all do
          namespace.add_owner(real_user)
        end

        let(:existing_membership_logged_params) do
          {
            'id' => real_user.members.first.id,
            'access_level' => Gitlab::Access::OWNER,
            'source_id' => namespace.id,
            'source_type' => 'Namespace',
            'user_id' => real_user.id
          }
        end

        it 'does not create the project membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of higher access level found for user, skipping',
            { 'project_id' => project.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { project.reload.members.count }
        end

        it 'does not create the group membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of higher access level found for user, skipping',
            { 'group_id' => subgroup.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { subgroup.reload.members.count }
        end
      end

      context 'when user has existing lower level DIRECT membership' do
        before_all do
          project.add_guest(real_user)
        end

        it 'does not create a new membership, and logs' do
          expect_skipped_membership_log(
            'Existing direct membership of lower or equal access level found for user, skipping',
            {
              'project_id' => project.id
            },
            {
              'id' => real_user.members.first.id,
              'access_level' => Gitlab::Access::GUEST,
              'source_id' => project.id,
              'source_type' => 'Project',
              'user_id' => real_user.id
            }
          )

          expect { service.execute }.not_to change { project.reload.members.count }
        end
      end

      context 'when user has existing same level DIRECT membership' do
        before_all do
          project.add_developer(real_user)
        end

        it 'does not create a new membership, and logs' do
          expect_skipped_membership_log(
            'Existing direct membership of lower or equal access level found for user, skipping',
            {
              'project_id' => project.id
            },
            {
              'id' => real_user.members.first.id,
              'access_level' => Gitlab::Access::DEVELOPER,
              'source_id' => project.id,
              'source_type' => 'Project',
              'user_id' => real_user.id
            }
          )

          expect { service.execute }.not_to change { project.reload.members.count }
        end
      end

      context 'when user has existing higher level DIRECT membership' do
        before_all do
          project.add_owner(real_user)
        end

        it 'does not create a new membership' do
          expect { service.execute }.not_to change { project.reload.members.count }
        end
      end

      def expect_skipped_membership_log(message, placeholder_membership, existing_membership)
        allow(Import::Framework::Logger).to receive(:info).and_call_original

        expect(Import::Framework::Logger)
          .to receive(:info)
          .with(
            hash_including(
              message: message,
              placeholder_membership: hash_including(placeholder_membership),
              existing_membership: hash_including(existing_membership),
              source_user_id: source_user.id
            )
          )
      end
    end

    context 'when the destination user is an admin' do
      before do
        source_user.reassign_to_user.update!(admin: true)
      end

      it 'logs a warning' do
        expect(::Import::Framework::Logger).to receive(:warn).with(
          hash_including(
            message: 'Reassigning contributions to user with admin privileges',
            namespace: namespace.full_path,
            source_hostname: source_user.source_hostname,
            source_user_id: source_user.id,
            reassign_to_user_id: source_user.reassign_to_user_id,
            reassigned_by_user_id: source_user.reassigned_by_user_id
          )
        )

        service.execute
      end

      it_behaves_like 'a successful reassignment'
    end

    context 'when the destination user has a different domain from the user who triggered the reassign' do
      let_it_be(:reassigned_by_user_at_gitlab) { create(:user, email: "123@gitlab.com") }
      let_it_be(:reassign_to_user_at_example) { create(:user, email: "xyz@example.com") }

      let_it_be_with_reload(:source_user) do
        create(:import_source_user,
          :reassignment_in_progress,
          reassigned_by_user: reassigned_by_user_at_gitlab,
          reassign_to_user: reassign_to_user_at_example,
          namespace: namespace
        )
      end

      it 'logs a warning' do
        message =
          'Reassigning contributions to user with different email host from user who triggered the reassignment'

        expect(::Import::Framework::Logger).to receive(:warn).with(
          hash_including(
            message: message,
            namespace: namespace.full_path,
            source_hostname: source_user.source_hostname,
            source_user_id: source_user.id,
            reassign_to_user_id: reassign_to_user_at_example.id,
            reassigned_by_user_id: reassigned_by_user_at_gitlab.id
          )
        )

        service.execute
      end

      it_behaves_like 'a successful reassignment'
    end

    context 'when the contributor user is not an admin and has the same domain as the importer user' do
      it 'does not log a warning' do
        expect(::Import::Framework::Logger).not_to receive(:warn)

        service.execute
      end

      it_behaves_like 'a successful reassignment'
    end

    context 'when the source user is not in reassignment_in_progress status' do
      before do
        source_user.complete!
      end

      it 'does not reassign any contributions or create memberships' do
        expect { service.execute }.to not_change { merge_requests[0].reload.author_id }.from(placeholder_user_id)
          .and not_change { merge_requests[1].reload.author_id }.from(placeholder_user_id)
          .and not_change { merge_requests[2].reload.author_id }.from(placeholder_user_id)
          .and not_change { merge_request_approval.reload.user_id }.from(placeholder_user_id)
          .and not_change { merge_request_approval_2.reload.user_id }.from(placeholder_user_id)
          .and not_change { issue.reload.author_id }.from(placeholder_user_id)
          .and not_change { authored_note.reload.author_id }.from(placeholder_user_id)
          .and not_change { updated_note.reload.updated_by_id }.from(placeholder_user_id)
          .and not_change { IssueAssignee.where({ user_id: real_user_id, issue_id: issue.id }).count }.from(0)
          .and not_change { Member.count }
      end

      it 'does not complete the source user' do
        expect { service.execute }.to not_change { source_user.status }
      end

      it 'does not delete any placeholder references or memberships' do
        expect { service.execute }
          .to not_change { Import::SourceUserPlaceholderReference.count }
          .and not_change { Import::Placeholders::Membership.count }
      end
    end

    context 'when a placeholder reference model and column have been renamed' do
      let_it_be(:old_model) { 'OldModel' }
      let_it_be(:old_user_reference_column) { 'olduser_id' }

      let_it_be(:merge_request_referenced_by_old_name) { create(:merge_request, author_id: placeholder_user_id) }

      let_it_be(:outdated_placeholder_reference) do
        create(
          :import_source_user_placeholder_reference,
          source_user: source_user,
          model: old_model,
          numeric_key: merge_request_referenced_by_old_name.id,
          alias_version: 1,
          user_reference_column: old_user_reference_column
        )
      end

      before do
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_model).and_call_original
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_column).and_call_original

        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_model)
          .with('OldModel', version: 1).and_return(MergeRequest)

        allow(Import::PlaceholderReferences::AliasResolver).to receive(:aliased_column)
          .with('OldModel', 'olduser_id', version: 1).and_return('author_id')
      end

      it 'reassigns the right record' do
        expect { service.execute }.to change { merge_request_referenced_by_old_name.reload.author_id }
          .from(placeholder_user_id).to(real_user_id)
      end
    end

    context 'when a placeholder reference is for a nonexistant model' do
      let_it_be(:invalid_model) { 'ThisWillNeverMapToARealModel' }
      let_it_be(:user_reference_column) { 'user_id' }

      let_it_be(:invalid_placeholder_reference) do
        create(
          :import_source_user_placeholder_reference,
          source_user: source_user,
          model: invalid_model,
          user_reference_column: user_reference_column
        )
      end

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      end

      it 'logs an error' do
        expect(::Import::Framework::Logger).to receive(:error).with(
          hash_including(
            message: "#{invalid_model} is not a model, #{user_reference_column} cannot be reassigned.",
            error: "ALIASES must be extended to include ThisWillNeverMapToARealModel for version 1",
            source_user_id: source_user.id
          )
        )

        service.execute
      end

      it 'does not delete the invalid placeholder reference' do
        expect { service.execute }.not_to change { invalid_placeholder_reference.reload.present? }.from(true)
      end

      it 'completes the reassignment' do
        service.execute

        expect(source_user.reload).to be_completed
      end
    end

    context 'when a record is no longer unique before reassignment' do
      let_it_be_with_reload(:duplicate_merge_request_approval) do
        create(:approval, merge_request: other_merge_request, user_id: real_user_id)
      end

      it 'updates actual records except non-unique record' do
        expect { service.execute }.to change { merge_requests[0].reload.author_id }
          .from(placeholder_user_id).to(real_user_id)
          .and change { merge_requests[1].reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { merge_requests[2].reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { merge_request_approval_2.reload.user_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue.reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue.reload.closed_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { issue_closed.reload.closed_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { authored_note.reload.author_id }.from(placeholder_user_id).to(real_user_id)
          .and change { updated_note.reload.updated_by_id }.from(placeholder_user_id).to(real_user_id)
          .and change { IssueAssignee.where({ user_id: real_user_id, issue_id: issue.id }).count }.from(0).to(1)

        expect { service.execute }.not_to change { merge_request_approval.reload.user_id }.from(placeholder_user_id)
      end

      it 'logs a warning' do
        expect(::Import::Framework::Logger).to receive(:warn).with({
          message: "Unable to reassign record, reassigned user is invalid or not unique",
          source_user_id: source_user.id
        })

        service.execute
      end

      it 'does not delete placeholder references for unassigned records' do
        expect { service.execute }.to change {
          Import::SourceUserPlaceholderReference.where(source_user: source_user).count
        }.to(1)

        expect(
          Import::SourceUserPlaceholderReference.where(source_user: source_user).pluck(:numeric_key)
        ).to eq([merge_request_approval.id])
      end

      it_behaves_like 'a successful reassignment'
    end
  end

  context 'when database is healthy' do
    before do
      allow(service).to receive_messages(db_health_check!: nil, db_table_unhealthy: false)
    end

    it 'checks all tables and individual tables' do
      expect(service).to receive(:db_health_check!).at_least(:once)
      expect(service).to receive(:db_table_unavailable?).at_least(:once)

      service.execute
    end

    context 'when :reassignment_throttling is disabled' do
      before do
        stub_feature_flags(reassignment_throttling: false)
      end

      it 'does not check database health' do
        expect(service).not_to receive(:db_health_check!)
        expect(service).not_to receive(:db_table_unavailable?)

        service.execute
      end
    end
  end

  context 'when database is unhealthy' do
    let(:db_table_health_failure) { described_class::DatabaseHealthError.new("#{User.table_name} table unavailable") }
    let(:db_health_failure) { described_class::DatabaseHealthError.new("Database unhealthy") }

    it 'returns a reschedule response when checking global tables' do
      allow(service).to receive(:db_health_check!).and_raise(db_health_failure)

      result = service.execute

      expect(result.status).to eq(:ok)
      expect(result.reason).to eq(:db_health_check_failed)
      expect(result.message).to eq('Rescheduling placeholder user records reassignment: database health')
    end

    it 'logs a warning' do
      allow(service).to receive(:db_health_check!).and_raise(db_health_failure)

      expect(::Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          message: "Database unhealthy. Rescheduling reassignment",
          source_user_id: source_user.id
        )
      )

      service.execute
    end

    it 'returns a reschedule response when checking a single table' do
      allow(service).to receive(:db_table_unavailable?).and_return true

      result = service.execute

      expect(result.status).to eq(:ok)
      expect(result.reason).to eq(:db_health_check_failed)
      expect(result.message).to eq('Rescheduling placeholder user records reassignment: database health')
    end

    it 'logs a warning when checking a single table' do
      allow(service).to receive(:reassign_placeholder_references).and_raise(db_table_health_failure)

      expect(::Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          message: "users table unavailable. Rescheduling reassignment",
          source_user_id: source_user.id
        )
      )

      service.execute
    end
  end

  describe '#db_table_unavailable?' do
    let(:health_status) { Gitlab::Database::HealthStatus }
    let(:table_health_indicator_class) { health_status::Indicators::AutovacuumActiveOnTable }
    let(:table_health_indicator) { instance_double(table_health_indicator_class) }
    let(:stop) { true }
    let(:stop_signal) do
      instance_double(
        "#{health_status}::Signals::Stop",
        log_info?: true,
        stop?: stop,
        indicator_class: table_health_indicator_class,
        short_name: 'Stop',
        reason: 'Test Exception'
      )
    end

    before do
      allow(table_health_indicator_class).to receive(:new).with(anything).and_return(table_health_indicator)
      allow(table_health_indicator).to receive(:evaluate).and_return(stop_signal)
    end

    context 'when a table is unavailable' do
      it 'returns true' do
        expect(service.send(:db_table_unavailable?, User)).to be true
      end
    end

    context 'when the table is available' do
      let(:stop) { false }

      it 'returns false' do
        expect(service.send(:db_table_unavailable?, User)).to be false
      end
    end
  end

  describe '#db_health_check!' do
    let(:health_status) { Gitlab::Database::HealthStatus }
    let(:health_status_indicator_class) { health_status::Indicators::WriteAheadLog }
    let(:health_status_indicator) { instance_double(health_status_indicator_class) }
    let(:stop) { false }
    let(:stop_signal) do
      instance_double(
        "#{health_status}::Signals::Stop",
        log_info?: true,
        stop?: stop,
        indicator_class: health_status_indicator_class,
        short_name: 'Stop',
        reason: 'Test Exception'
      )
    end

    before do
      allow(service).to receive(:check_db_health?).and_return(true)
      allow(health_status_indicator_class).to receive(:new).with(anything).and_return(health_status_indicator)
      allow(health_status_indicator).to receive(:evaluate).and_return(stop_signal)
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    context 'when caching health status' do
      after do
        travel_back
      end

      it 'caches the result for 30 seconds' do
        expect(Rails.cache).to receive(:fetch).with(
          "reassign_placeholder_user_records_service_db_check",
          { expires_in: 30.seconds }
        ).thrice.and_yield

        service.send(:db_health_check!)

        travel 25.seconds
        service.send(:db_health_check!)

        travel 6.seconds
        service.send(:db_health_check!)
      end
    end

    context 'when the database is unhealthy' do
      let(:stop) { true }

      it 'raises an error' do
        expect { service.send(:db_health_check!) }.to raise_error(described_class::DatabaseHealthError)
      end
    end

    context 'when the database is healthy' do
      let(:stop) { false }

      it 'returns nil' do
        expect(service.send(:db_health_check!)).to be_nil
      end
    end
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
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
