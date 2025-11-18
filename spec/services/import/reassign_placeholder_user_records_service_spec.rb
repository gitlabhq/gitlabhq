# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ReassignPlaceholderUserRecordsService, feature_category: :importers do
  include_context 'with reassign placeholder user records'

  let_it_be(:real_user) { source_user.reassign_to_user }
  let_it_be(:real_user_id) { real_user.id }

  before do
    allow(Kernel).to receive(:sleep)
  end

  describe '#execute', :aggregate_failures do
    before do
      allow(service).to receive_messages(db_health_check!: nil, db_table_unavailable?: false)
    end

    context 'when a user can be reassigned without error' do
      context 'when contributions is assigned to the import user type' do
        before do
          import_user.update!(user_type: :import_user)
        end

        it_behaves_like 'a successful reassignment'

        it_behaves_like 'reassigns placeholder user records' do
          let(:reassign_user_id) { real_user_id }
        end

        it_behaves_like 'handles membership creation for reassigned users' do
          let(:reassign_user) { real_user }
        end

        it 'does not log when placeholder references are used' do
          expect(Import::Framework::Logger).not_to receive(:info).with(
            hash_including(message: 'Placeholder references used')
          )

          service.execute
        end
      end

      context 'when contributions is assigned to the placeholder user type' do
        before do
          import_user.update!(user_type: :placeholder)
        end

        it_behaves_like 'a successful reassignment'

        it_behaves_like 'reassigns placeholder user records' do
          let(:reassign_user_id) { real_user_id }
        end

        it_behaves_like 'handles membership creation for reassigned users' do
          let(:reassign_user) { real_user }
        end

        it 'logs when placeholder references are used' do
          allow(Import::Framework::Logger).to receive(:info)
          expect(Import::Framework::Logger).to receive(:info).with(
            hash_including(
              message: 'Placeholder references used',
              model: "Note",
              user_reference_column: 'updated_by_id'
            )
          )

          expect(Import::Framework::Logger).not_to receive(:info).with(
            hash_including(
              message: 'Placeholder references used',
              model: "Note",
              user_reference_column: 'author_id'
            )
          )

          service.execute
        end

        context 'when user_mapping_direct_reassignment feature flag is disabled' do
          before do
            stub_feature_flags(user_mapping_direct_reassignment: false)
          end

          it 'does not log when placeholder references are used' do
            expect(Import::Framework::Logger).not_to receive(:info).with(
              hash_including(message: 'Placeholder references used')
            )

            service.execute
          end
        end
      end

      it 'sleeps between processing each model relation batch' do
        expect(Kernel).to receive(:sleep).with(0.01).exactly(8).times

        service.execute
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

      context 'when reassign to user is a project bot' do
        before do
          source_user.update!(reassign_to_user: project_bot)
        end

        it_behaves_like 'a successful reassignment'

        it_behaves_like 'reassigns placeholder user records' do
          let(:reassign_user_id) { project_bot.id }
        end

        it 'does not create memberships' do
          service.execute

          expect(subgroup.reload.members).to be_empty
          expect(project.reload.members).to be_empty
        end
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
          namespace.add_developer(real_user)
        end

        let(:existing_membership_logged_params) do
          {
            'id' => real_user.members.first.id,
            'access_level' => Gitlab::Access::DEVELOPER,
            'source_id' => namespace.id,
            'source_type' => 'Namespace',
            'user_id' => real_user.id
          }
        end

        it 'does not create the project membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of same or higher access level found for user, skipping',
            { 'project_id' => project.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { project.reload.members.count }
        end

        it 'does not create the group membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of same or higher access level found for user, skipping',
            { 'group_id' => subgroup.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { subgroup.reload.members.count }
        end

        it 'still calls UserProjectAccessChangedService when project memberships are skipped' do
          expect_next_instance_of(UserProjectAccessChangedService, reassign_to_user.id) do |service|
            expect(service).to receive(:execute)
          end

          service.execute
        end

        it 'does not call UserProjectAccessChangedService when only group memberships are skipped' do
          Import::Placeholders::Membership.where(project: project).delete_all

          expect(UserProjectAccessChangedService).not_to receive(:new)

          expect { service.execute }.not_to change { subgroup.reload.members.count }
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
            'Existing membership of same or higher access level found for user, skipping',
            { 'project_id' => project.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { project.reload.members.count }
        end

        it 'does not create the group membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of same or higher access level found for user, skipping',
            { 'group_id' => subgroup.id }, existing_membership_logged_params
          )

          expect { service.execute }.not_to change { subgroup.reload.members.count }
        end

        it 'still calls UserProjectAccessChangedService when project memberships are skipped' do
          expect_next_instance_of(UserProjectAccessChangedService, reassign_to_user.id) do |service|
            expect(service).to receive(:execute)
          end

          service.execute
        end
      end

      context 'when user has existing lower level DIRECT membership' do
        before_all do
          project.add_guest(real_user)
        end

        it 'does not create a new membership, and logs' do
          expect_skipped_membership_log(
            'Existing direct membership of lower access level found for user, skipping',
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

        it 'does not call UserProjectAccessChangedService' do
          expect(UserProjectAccessChangedService).not_to receive(:new)

          expect { service.execute }.not_to change { project.reload.members.count }
        end
      end

      context 'when user has existing same level DIRECT membership' do
        before_all do
          project.add_developer(real_user)
        end

        it 'does not create a new membership, and logs' do
          expect_skipped_membership_log(
            'Existing membership of same or higher access level found for user, skipping',
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

        it 'does not call UserProjectAccessChangedService' do
          expect(UserProjectAccessChangedService).not_to receive(:new)

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

        it 'does not call UserProjectAccessChangedService' do
          expect(UserProjectAccessChangedService).not_to receive(:new)

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
            error: "ALIASES must be extended to include ThisWillNeverMapToARealModel for version 1. See " \
              "#{Import::PlaceholderReferences::AliasResolver::DOCS_URL} for more information",
            source_user_id: source_user.id
          )
        )

        service.execute
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

      it 'deletes placeholder references for unassigned records' do
        expect { service.execute }.to change {
          Import::SourceUserPlaceholderReference.where(source_user: source_user).count
        }.to(0)
      end

      it_behaves_like 'a successful reassignment'
    end
  end

  context 'when database is healthy' do
    it 'checks all tables and individual tables' do
      expect_next_instance_of(Import::ReassignPlaceholderThrottling) do |throttling|
        expect(throttling).to receive(:db_health_check!).at_least(:once).and_call_original
        expect(throttling).to receive(:db_table_unavailable?).at_least(:once).and_call_original
      end

      service.execute
    end
  end

  context 'when database is unhealthy' do
    before do
      allow_next_instance_of(Import::ReassignPlaceholderThrottling) do |throttling|
        allow(throttling).to receive(:db_health_check!)
          .and_raise(Import::ReassignPlaceholderThrottling::DatabaseHealthError, 'Database unhealthy')
        allow(throttling).to receive(:db_table_unavailable?).and_return(false)
      end
    end

    it 'returns a reschedule response when checking global tables' do
      result = service.execute

      expect(result.status).to eq(:error)
      expect(result.reason).to eq(:db_health_check_failed)
      expect(result.message).to eq('Database unhealthy')
    end

    it 'logs a warning' do
      expect(::Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          message: "Database unhealthy. Rescheduling reassignment",
          source_user_id: source_user.id
        )
      )

      service.execute
    end

    context 'when tables were unavailable' do
      before do
        allow_next_instance_of(Import::ReassignPlaceholderThrottling) do |throttling|
          allow(throttling).to receive(:db_health_check!)
          allow(throttling).to receive(:db_table_unavailable?)
          allow(throttling).to receive(:unavailable_tables?).and_return(true)
        end
      end

      it 'returns a reschedule response' do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.reason).to eq(:db_health_check_failed)
        expect(result.message).to eq('Database unhealthy')
      end
    end
  end

  context 'when execution time exceeds the limit' do
    before do
      allow_next_instance_of(Import::DirectReassignService) do |service|
        allow(service).to receive(:execute)
          .and_raise(Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError, 'Execution timeout')
      end
    end

    it 'logs a warn' do
      expect(::Import::Framework::Logger).to receive(:warn).with(
        hash_including(
          message: "Execution timeout. Rescheduling reassignment",
          source_user_id: source_user.id
        )
      )

      service.execute
    end

    it 'returns a execution timeout error' do
      result = service.execute

      expect(result).to be_error
      expect(result.reason).to eq(:execution_timeout)
    end
  end
end
