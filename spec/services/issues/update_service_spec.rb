# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::UpdateService, :mailer, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group) { create(:group, :public, maintainers: user, developers: [user2, user3], guests: guest) }
  let_it_be(:project, reload: true) { create(:project, :repository, group: group) }
  let_it_be(:label) { create(:label, title: 'a', project: project) }
  let_it_be(:label2) { create(:label, title: 'b', project: project) }
  let_it_be(:label3) { create(:label, title: 'c', project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:container) { project }
  let(:issue) do
    create(
      :issue,
      :unchanged,
      title: 'Old title',
      description: "for #{user2.to_reference}",
      assignee_ids: [user3.id],
      project: project,
      author: create(:user),
      created_at: Time.current - 1.day,
      updated_at: Time.current - 1.day
    )
  end

  describe 'execute' do
    let_it_be(:contact) { create(:contact, group: group) }

    def find_note(starting_with)
      issue.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def find_notes(action)
      issue
        .notes
        .joins(:system_note_metadata)
        .where(system_note_metadata: { action: action })
    end

    def update_issue(opts)
      described_class.new(container: container, current_user: user, params: opts).execute(issue)
    end

    it_behaves_like 'issuable update service updating last_edited_at values' do
      let(:issuable) { issue }
      subject(:update_issuable) { update_issue(update_params) }
    end

    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_ids: [user2.id],
          state_event: 'close',
          label_ids: [label&.id],
          due_date: Date.tomorrow,
          discussion_locked: true,
          severity: 'low',
          milestone_id: milestone.id,
          add_contacts: [contact.email]
        }
      end

      context 'when an unauthorized project_id is provided' do
        let(:unauthorized_project) { create(:project) }

        before do
          opts[:project_id] = unauthorized_project.id
        end

        it 'ignores the project_id param and does not update the issue\'s project' do
          expect do
            update_issue(opts)
            unauthorized_project.reload
          end.to not_change { unauthorized_project.issues.count }

          expect(issue.project).to eq(project)
        end
      end

      it 'updates the issue with the given params' do
        expect(TodosDestroyer::ConfidentialIssueWorker).not_to receive(:perform_in)

        update_issue(opts)

        expect(issue).to be_valid
        expect(issue.title).to eq 'New title'
        expect(issue.description).to eq 'Also please fix'
        expect(issue.assignees).to match_array([user2])
        expect(issue).to be_closed
        expect(issue.labels).to match_array [label]
        expect(issue.due_date).to eq Date.tomorrow
        expect(issue.discussion_locked).to be_truthy
        expect(issue.confidential).to be_falsey
        expect(issue.milestone).to eq milestone
        expect(issue.issue_customer_relations_contacts.last.contact).to eq contact
      end

      context 'with lock_version' do
        let(:opts) do
          {
            description: 'Also please fix',
            label_ids: [label.id]
          }
        end

        context 'when given lock_version is valid' do
          before do
            opts[:lock_version] = issue.lock_version
          end

          it 'updates the issue successfully' do
            update_issue(opts)

            expect(issue).to be_valid
          end
        end

        context 'when given lock_version is stale' do
          before do
            opts[:lock_version] = issue.lock_version - 1
          end

          it 'raises a stale object error' do
            expect { update_issue(opts) }.to raise_error ActiveRecord::StaleObjectError
          end
        end
      end

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        subject(:execute_service) { update_issue(opts) }
      end

      context 'when updating milestone' do
        before do
          update_issue({ milestone_id: nil })
        end

        it 'updates issue milestone when passing `milestone` param' do
          expect { update_issue({ milestone_id: milestone.id }) }
            .to change(issue, :milestone).to(milestone).from(nil)
        end

        it "triggers 'issuableMilestoneUpdated'" do
          expect(GraphqlTriggers).to receive(:issuable_milestone_updated).with(issue).and_call_original

          update_issue({ milestone_id: milestone.id })
        end

        context 'when milestone remains unchanged' do
          before do
            update_issue({ title: 'abc', milestone_id: milestone.id })
          end

          it "does not trigger 'issuableMilestoneUpdated'" do
            expect(GraphqlTriggers).not_to receive(:issuable_milestone_updated)

            update_issue({ milestone_id: milestone.id })
          end
        end
      end

      context 'when sentry identifier is given' do
        before do
          sentry_attributes = { sentry_issue_attributes: { sentry_issue_identifier: 42 } }
          opts.merge!(sentry_attributes)
        end

        it 'assigns the sentry error' do
          update_issue(opts)

          expect(issue.sentry_issue).to be_kind_of(SentryIssue)
        end

        context 'user is a guest' do
          let(:user) { guest }

          it 'does not assign the sentry error' do
            update_issue(opts)

            expect(issue.sentry_issue).to eq(nil)
          end
        end
      end

      context 'when issue type is not incident' do
        before do
          update_issue(opts)
        end

        it_behaves_like 'not an incident issue'

        context 'when confidentiality is changed' do
          subject { update_issue(confidential: true) }

          it_behaves_like 'does not track incident management event'
        end
      end

      context 'when issue type is incident' do
        let(:issue) { create(:incident, project: project) }

        before do
          update_issue(opts)
        end

        it_behaves_like 'incident issue'

        it 'does not add an incident label' do
          expect(issue.labels).to match_array [label]
        end

        context 'when confidentiality is changed' do
          let(:current_user) { user }

          subject { update_issue(confidential: true) }

          it_behaves_like 'an incident management tracked event', :incident_management_incident_change_confidential

          it_behaves_like 'Snowplow event tracking with RedisHLL context' do
            let(:namespace) { issue.namespace }
            let(:category) { described_class.to_s }
            let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
            let(:action) { 'incident_management_incident_change_confidential' }
            let(:opts) do
              {
                title: 'New title',
                description: 'Also please fix',
                assignee_ids: [user2.id],
                state_event: 'close',
                due_date: Date.tomorrow,
                discussion_locked: true,
                severity: 'low',
                milestone_id: milestone.id,
                add_contacts: [contact.email]
              }
            end
          end
        end
      end

      it 'refreshes the number of open issues when the issue is made confidential', :use_clean_rails_memory_store_caching do
        issue # make sure the issue is created first so our counts are correct.

        expect do
          update_issue(confidential: true)

          BatchLoader::Executor.clear_current
        end.to change { project.open_issues_count }.from(1).to(0)
      end

      it 'enqueues ConfidentialIssueWorker when an issue is made confidential' do
        expect(TodosDestroyer::ConfidentialIssueWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, issue.id)

        update_issue(confidential: true)

        expect(issue.confidential).to be_truthy
      end

      it 'does not enqueue ConfidentialIssueWorker when an issue is made non confidential' do
        # set confidentiality to true before the actual update
        issue.update!(confidential: true)

        expect(TodosDestroyer::ConfidentialIssueWorker).not_to receive(:perform_in)

        update_issue(confidential: false)

        expect(issue.confidential).to be_falsey
      end

      context 'changing issue_type' do
        let!(:label_1) { create(:label, project: project, title: 'incident') }
        let!(:label_2) { create(:label, project: project, title: 'missed-sla') }

        before do
          stub_licensed_features(quality_management: true)
        end

        context 'from issue to incident' do
          it_behaves_like 'incident issue' do
            before do
              update_issue(**opts, issue_type: 'incident')
            end
          end

          it 'creates system note about issue type' do
            update_issue(issue_type: 'incident')

            note = find_note('changed type from issue to incident')

            expect(note).not_to eq(nil)
          end

          it 'creates an escalation status' do
            expect { update_issue(issue_type: 'incident') }
            .to change { issue.reload.incident_management_issuable_escalation_status }
            .from(nil)
            .to(a_kind_of(IncidentManagement::IssuableEscalationStatus))
          end

          context 'for an issue with multiple labels' do
            let(:issue) { create(:incident, project: project, labels: [label_1]) }

            before do
              update_issue(issue_type: 'incident')
            end

            it 'does not add an `incident` label if one already exist' do
              expect(issue.labels).to eq([label_1])
            end
          end
        end

        context 'from incident to issue' do
          let(:issue) { create(:incident, project: project) }

          it 'changed from an incident to an issue type' do
            expect { update_issue(issue_type: 'issue') }
              .to change(issue, :issue_type).from('incident').to('issue')
              .and(change { issue.work_item_type.base_type }.from('incident').to('issue'))
          end

          context 'for an incident with multiple labels' do
            let(:issue) { create(:incident, project: project, labels: [label_1, label_2]) }

            it 'does not remove an `incident` label if one exists on the incident' do
              expect { update_issue(issue_type: 'issue') }.to not_change(issue, :label_ids)
            end
          end

          context 'filtering the incident label' do
            let(:issue) { create(:incident, project: project, labels: [label_1, label_2]) }
            let(:params) { { label_ids: [label_1.id, label_2.id], remove_label_ids: [] } }

            it 'does not add an incident label id to remove_label_ids for it to be removed' do
              expect { update_issue(issue_type: 'issue') }.to not_change(issue, :label_ids)
            end
          end
        end

        context 'from issue to restricted issue types' do
          context 'without sufficient permissions' do
            let(:user) { guest }

            it 'does nothing to the labels' do
              expect { update_issue(issue_type: 'issue') }.not_to change(issue.labels, :count)
              expect(issue.reload.labels).to eq([])
            end
          end
        end
      end

      it 'updates open issue counter for assignees when issue is reassigned' do
        update_issue(assignee_ids: [user2.id])

        expect(user3.assigned_open_issues_count).to eq 0
        expect(user2.assigned_open_issues_count).to eq 1
      end

      context 'when changing relative position' do
        let(:issue1) { create(:issue, project: project, assignees: [user3]) }
        let(:issue2) { create(:issue, project: project, assignees: [user3]) }

        before do
          [issue, issue1, issue2].each do |issue|
            issue.move_to_end
            issue.save!
          end
        end

        it 'sorts issues as specified by parameters' do
          opts[:move_between_ids] = [issue1.id, issue2.id]

          update_issue(opts)

          expect(issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
        end

        context 'when block_issue_positioning flag is enabled' do
          before do
            stub_feature_flags(block_issue_repositioning: true)
          end

          it 'raises error' do
            old_position = issue.relative_position
            opts[:move_between_ids] = [issue1.id, issue2.id]

            expect { update_issue(opts) }.to raise_error(::Gitlab::RelativePositioning::IssuePositioningDisabled)
            expect(issue.reload.relative_position).to eq(old_position)
          end
        end
      end

      it 'rebalances if needed on the left' do
        range = described_class::NO_REBALANCING_NEEDED
        issue1 = create(:issue, project: project, relative_position: range.first - 100)
        issue2 = create(:issue, project: project, relative_position: range.first)
        issue.update!(relative_position: RelativePositioning::START_POSITION)

        opts[:move_between_ids] = [issue1.id, issue2.id]

        expect(Issues::RebalancingWorker).to receive(:perform_async).with(nil, nil, project.root_namespace.id)

        update_issue(opts)
        expect(issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
      end

      it 'rebalances if needed on the right' do
        range = described_class::NO_REBALANCING_NEEDED
        issue1 = create(:issue, project: project, relative_position: range.last)
        issue2 = create(:issue, project: project, relative_position: range.last + 100)
        issue.update!(relative_position: RelativePositioning::START_POSITION)

        opts[:move_between_ids] = [issue1.id, issue2.id]

        expect(Issues::RebalancingWorker).to receive(:perform_async).with(nil, nil, project.root_namespace.id)

        update_issue(opts)
        expect(issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
      end

      context 'when moving issue between issues from different projects' do
        let(:group) { create(:group) }
        let(:subgroup) { create(:group, parent: group) }

        let(:project_1) { create(:project, namespace: group) }
        let(:project_2) { create(:project, namespace: group) }
        let(:project_3) { create(:project, namespace: subgroup) }

        let(:issue_1) { create(:issue, project: project_1) }
        let(:issue_2) { create(:issue, project: project_2) }
        let(:issue_3) { create(:issue, project: project_3) }

        before do
          group.add_developer(user)
        end

        it 'sorts issues as specified by parameters' do
          # Moving all issues to end here like the last example won't work since
          # all projects only have the same issue count
          # so their relative_position will be the same.
          issue_1.move_to_end
          issue_2.move_after(issue_1)
          issue_3.move_after(issue_2)
          [issue_1, issue_2, issue_3].map(&:save)

          opts[:move_between_ids] = [issue_1.id, issue_2.id]

          described_class.new(container: issue_3.project, current_user: user, params: opts).execute(issue_3)
          expect(issue_2.relative_position).to be_between(issue_1.relative_position, issue_2.relative_position)
        end
      end

      context 'when current user cannot admin issues in the project' do
        it 'filters out params that cannot be set without the :admin_issue permission' do
          issue.update!(author: guest)

          described_class.new(
            container: project, current_user: guest, params: opts.merge(
              confidential: true,
              issue_type: 'test_case'
            )
          ).execute(issue)

          expect(issue).to be_valid
          expect(issue.title).to eq 'New title'
          expect(issue.description).to eq 'Also please fix'
          expect(issue.assignees).to match_array [user3]
          expect(issue.labels).to be_empty
          expect(issue.milestone).to be_nil
          expect(issue.due_date).to be_nil
          expect(issue.discussion_locked).to be_falsey
          expect(issue.confidential).to be_falsey
          expect(issue.issue_type).to eql('issue')
        end
      end

      context 'with background jobs processed', :sidekiq_might_not_need_inline do
        before do
          perform_enqueued_jobs do
            update_issue(opts)
          end
        end

        it 'sends email to user2 about assign of new issue and email to user3 about issue unassignment' do
          deliveries = ActionMailer::Base.deliveries
          email = deliveries.last
          recipients = deliveries.last(2).flat_map(&:to)
          expect(recipients).to include(user2.email, user3.email)
          expect(email.subject).to include(issue.title)
        end

        it 'creates system note about issue reassign' do
          note = find_note('assigned to')

          expect(note.note).to include "assigned to #{user2.to_reference}"
        end

        it 'creates a resource label event' do
          event = issue.resource_label_events.last

          expect(event).not_to be_nil
          expect(event.label_id).to eq label.id
          expect(event.user_id).to eq user.id
        end

        it 'creates system note about title change' do
          note = find_note('changed title')

          expect(note.note).to eq 'changed title from **{-Old-} title** to **{+New+} title**'
        end

        it 'creates system note about discussion lock' do
          note = find_note('locked the discussion in this issue')

          expect(note.note).to eq 'locked the discussion in this issue'
        end
      end

      context 'after_save callback to store_mentions' do
        let(:issue) { create(:issue, title: 'Old title', description: "simple description", project: project, author: create(:user)) }
        let(:labels) { create_pair(:label, project: project) }
        let(:milestone) { create(:milestone, project: project) }

        context 'when mentionable attributes change' do
          let(:opts) { { description: "Description with #{user.to_reference}" } }

          it 'saves mentions' do
            expect(issue).to receive(:store_mentions!).and_call_original

            expect { update_issue(opts) }.to change { IssueUserMention.count }.by(1)

            expect(issue.referenced_users).to match_array([user])
          end
        end

        context 'when mentionable attributes do not change' do
          let(:opts) { { label_ids: labels.map(&:id), milestone_id: milestone.id } }

          it 'does not call store_mentions' do
            expect(issue).not_to receive(:store_mentions!).and_call_original

            expect { update_issue(opts) }.not_to change { IssueUserMention.count }

            expect(issue.referenced_users).to be_empty
          end
        end

        context 'when save fails' do
          let(:opts) { { title: '', label_ids: labels.map(&:id), milestone_id: milestone.id } }

          it 'does not call store_mentions' do
            expect(issue).not_to receive(:store_mentions!).and_call_original

            expect { update_issue(opts) }.not_to change { IssueUserMention.count }

            expect(issue.referenced_users).to be_empty
            expect(issue.valid?).to be false
          end
        end
      end
    end

    context 'when description changed' do
      it 'creates system note about description change' do
        update_issue(description: 'Changed description')

        note = find_note('changed the description')

        expect(note.note).to eq('changed the description')
      end

      it 'triggers GraphQL description updated subscription' do
        expect(GraphqlTriggers).to receive(:issuable_description_updated).with(issue).and_call_original

        update_issue(description: 'Changed description')
      end
    end

    context 'when description is not changed' do
      it 'does not trigger GraphQL description updated subscription' do
        expect(GraphqlTriggers).not_to receive(:issuable_description_updated)

        update_issue(title: 'Changed title')
      end
    end

    context 'when issue turns confidential' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_ids: [user2],
          state_event: 'close',
          label_ids: [label.id],
          confidential: true
        }
      end

      it 'creates system note about confidentiality change' do
        update_issue(confidential: true)

        note = find_note('made the issue confidential')

        expect(note.note).to eq 'made the issue confidential'
      end

      it 'executes confidential issue hooks' do
        expect(project.project_namespace).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), :confidential_issue_hooks)

        update_issue(confidential: true)
      end

      it 'allows assignment of guest users' do
        update_issue(confidential: true)

        update_issue(assignee_ids: [guest.id])

        expect(issue.reload.assignees).to contain_exactly(guest)
      end

      it 'does not update assignee_id with unauthorized users' do
        update_issue(confidential: true)

        non_member = create(:user)
        original_assignees = issue.assignees.to_a

        update_issue(assignee_ids: [non_member.id])

        expect(issue.reload.assignees).to eq(original_assignees)
      end
    end

    context 'todos' do
      let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

      context 'when the title change' do
        before do
          update_issue(title: 'New title')
        end

        it 'marks pending todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'does not create any new todos' do
          expect(Todo.count).to eq(1)
        end
      end

      context 'when the description change' do
        before do
          update_issue(description: "Also please fix #{user2.to_reference} #{user3.to_reference}")
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'creates only 1 new todo' do
          expect(Todo.count).to eq(2)
        end
      end

      context 'when is reassigned' do
        before do
          update_issue(assignees: [user2])
        end

        it 'marks previous assignee todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'creates a todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: issue.id,
            target_type: issue.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end

      context 'when a new assignee added' do
        subject { update_issue(assignees: issue.assignees + [user2]) }

        it 'creates only 1 new todo' do
          expect { subject }.to change { Todo.count }.by(1)
        end

        it 'creates a todo for new assignee' do
          subject

          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: issue.id,
            target_type: issue.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq(1)
        end

        context 'issue is incident type' do
          let(:issue) { create(:incident, project: project) }
          let(:current_user) { user }

          it_behaves_like 'an incident management tracked event', :incident_management_incident_assigned

          it_behaves_like 'Snowplow event tracking with RedisHLL context' do
            let(:namespace) { issue.namespace }
            let(:category) { described_class.to_s }
            let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
            let(:action) { "incident_management_incident_assigned" }
          end
        end
      end

      context 'when the milestone is removed' do
        let!(:non_subscriber) { create(:user) }

        let!(:subscriber) do
          create(:user) do |u|
            issue.toggle_subscription(u, project)
            project.add_developer(u)
          end
        end

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          issue.milestone = create(:milestone, project: project)

          issue.save!

          perform_enqueued_jobs do
            update_issue(milestone_id: "")
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'clears milestone issue counters cache' do
          issue.milestone = create(:milestone, project: project)

          issue.save!

          expect_next_instance_of(Milestones::IssuesCountService, issue.milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, issue.milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end

          update_issue(milestone_id: "")
        end
      end

      context 'when the milestone is assigned' do
        let!(:non_subscriber) { create(:user) }

        let!(:subscriber) do
          create(:user) do |u|
            issue.toggle_subscription(u, project)
            project.add_developer(u)
          end
        end

        it 'marks todos as done' do
          update_issue(milestone_id: create(:milestone, project: project).id)

          expect(todo.reload.done?).to eq true
        end

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            update_issue(milestone_id: create(:milestone, project: project).id)
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'deletes issue counters cache for the milestone' do
          milestone = create(:milestone, project: project)

          expect_next_instance_of(Milestones::IssuesCountService, milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end

          update_issue(milestone_id: milestone.id)
        end

        context 'when also closing the issue' do
          it 'creates a milestone resource event' do
            expect do
              update_issue(milestone_id: create(:milestone, project: project).id, state_event: 'close')
            end.to change { ResourceMilestoneEvent.count }.by(1)
          end
        end
      end

      context 'when the milestone is changed' do
        it 'deletes issue counters cache for both milestones' do
          old_milestone = create(:milestone, project: project)
          new_milestone = create(:milestone, project: project)

          issue.update!(milestone: old_milestone)

          expect_next_instance_of(Milestones::IssuesCountService, old_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, old_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::IssuesCountService, new_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end
          expect_next_instance_of(Milestones::ClosedIssuesCountService, new_milestone) do |service|
            expect(service).to receive(:delete_cache).and_call_original
          end

          update_issue(milestone_id: new_milestone.id)
        end
      end

      context 'when the labels change' do
        before do
          travel_to(1.minute.from_now) do
            update_issue(label_ids: [label.id])
          end
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'updates updated_at' do
          expect(issue.reload.updated_at).to be_future
        end
      end
    end

    context 'when the issue is relabeled' do
      let!(:non_subscriber) { create(:user) }

      let!(:subscriber) do
        create(:user) do |u|
          label.toggle_subscription(u, project)
          project.add_developer(u)
        end
      end

      it 'sends notifications for subscribers of newly added labels', :sidekiq_might_not_need_inline do
        opts = { label_ids: [label.id] }

        perform_enqueued_jobs do
          @issue = described_class.new(container: project, current_user: user, params: opts).execute(issue)
        end

        should_email(subscriber)
        should_not_email(non_subscriber)
      end

      context 'when issue has the `label` label' do
        before do
          issue.labels << label
        end

        it 'does not send notifications for existing labels' do
          opts = { label_ids: [label.id, label2.id] }

          perform_enqueued_jobs do
            @issue = described_class.new(container: project, current_user: user, params: opts).execute(issue)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'does not send notifications for removed labels' do
          opts = { label_ids: [label2.id] }

          perform_enqueued_jobs do
            @issue = described_class.new(container: project, current_user: user, params: opts).execute(issue)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end
      end
    end

    context 'when issue has tasks' do
      before do
        update_issue(description: "- [ ] Task 1\n- [ ] Task 2")
      end

      it { expect(issue.tasks?).to eq(true) }

      it_behaves_like 'updating a single task'

      context 'when tasks are marked as completed' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
        end

        it 'does not check for spam on task status change' do
          params = {
            update_task: {
              index: 1,
              checked: false,
              line_source: '- [x] Task 1',
              line_number: 1
            }
          }
          service = described_class.new(container: project, current_user: user, params: params)

          expect(issue).not_to receive(:check_for_spam)

          service.execute(issue)
        end

        # At the moment of writting old associations are not necessary for update_task
        # and doing this will prevent fetching associations from the DB and comparing old and new labels
        it 'does not pass old_associations to the after_update method' do
          params = {
            update_task: {
              index: 1,
              checked: false,
              line_source: '- [x] Task 1',
              line_number: 1
            }
          }
          service = described_class.new(container: project, current_user: user, params: params)

          expect(service).to receive(:after_update).with(issue, {})

          service.execute(issue)
        end

        it 'creates system note about task status change' do
          note1 = find_note('marked the checklist item **Task 1** as completed')
          note2 = find_note('marked the checklist item **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
          update_issue(description: "- [ ] Task 1\n- [ ] Task 2")
        end

        it 'creates system note about task status change' do
          note1 = find_note('marked the checklist item **Task 1** as incomplete')
          note2 = find_note('marked the checklist item **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
        end
      end

      context 'when tasks position has been modified' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
          update_issue(description: "- [x] Task 1\n- [ ] Task 3\n- [ ] Task 2")
        end

        it 'does not create a system note for the task' do
          task_note = find_note('marked the checklist item **Task 2** as incomplete')
          description_notes = find_notes('description')

          expect(task_note).to be_nil
          expect(description_notes.length).to eq(2)
        end
      end

      context 'when a Task list with a completed item is totally replaced' do
        before do
          update_issue(description: "- [ ] Task 1\n- [X] Task 2")
          update_issue(description: "- [ ] One\n- [ ] Two\n- [ ] Three")
        end

        it 'does not create a system note referencing the position the old item' do
          task_note = find_note('marked the checklist item **Two** as incomplete')
          description_notes = find_notes('description')

          expect(task_note).to be_nil
          expect(description_notes.length).to eq(2)
        end

        it 'does not generate a new note at all' do
          expect do
            update_issue(description: "- [ ] One\n- [ ] Two\n- [ ] Three")
          end.not_to change { Note.count }
        end
      end
    end

    context 'updating labels' do
      let(:label_a) { label }
      let(:label_b) { label2 }
      let(:label_c) { label3 }
      let(:label_locked) { create(:label, title: 'locked', project: project, lock_on_merge: true) }
      let(:issuable) { issue }

      it_behaves_like 'updating issuable labels'
      it_behaves_like 'keeps issuable labels sorted after update'
      it_behaves_like 'broadcasting issuable labels updates'

      context 'when the issue belongs directly to a group' do
        let(:container) { group }

        it_behaves_like 'updating issuable labels'
      end

      def update_issuable(update_params)
        update_issue(update_params)
      end
    end

    context 'updating dates' do
      subject(:result) { described_class.new(container: project, current_user: user, params: params).execute(issue) }

      let(:updated_date) { 1.week.from_now.to_date }

      shared_examples 'issue update service that triggers date updates' do
        it 'triggers graphql date updated subscription' do
          expect(GraphqlTriggers).to receive(:issuable_dates_updated).with(issue).and_call_original

          result
        end
      end

      shared_examples 'issue update service that does not trigger date updates' do
        it 'does not trigger date updated subscriptions' do
          expect(GraphqlTriggers).not_to receive(:issuable_dates_updated)

          result
        end
      end

      context 'when due_date is updated' do
        let(:params) { { due_date: updated_date } }

        it_behaves_like 'issue update service that triggers date updates'
      end

      context 'when start_date is updated' do
        let(:params) { { start_date: updated_date } }

        it_behaves_like 'issue update service that triggers date updates'
      end

      context 'when no date is updated' do
        let(:params) { { title: 'should not trigger date updates' } }

        it_behaves_like 'issue update service that does not trigger date updates'
      end

      context 'when update is not successful but date is provided' do
        let(:params) { { title: '', due_date: updated_date } }

        it_behaves_like 'issue update service that does not trigger date updates'
      end
    end

    context 'updating asssignee_id' do
      it 'changes assignee' do
        expect_next_instance_of(NotificationService::Async) do |service|
          expect(service).to receive(:reassigned_issue).with(issue, user, [user3])
        end

        update_issue(assignee_ids: [user2.id])

        expect(issue.reload.assignees).to eq([user2])
      end

      it 'does not update assignee when assignee_id is invalid' do
        expect(NotificationService).not_to receive(:new)

        update_issue(assignee_ids: [-1])

        expect(issue.reload.assignees).to eq([user3])
      end

      it 'unassigns assignee when user id is 0' do
        expect_next_instance_of(NotificationService::Async) do |service|
          expect(service).to receive(:reassigned_issue).with(issue, user, [user3])
        end

        update_issue(assignee_ids: [0])

        expect(issue.reload.assignees).to be_empty
      end

      it 'does not update assignee_id when user cannot read issue' do
        expect(NotificationService).not_to receive(:new)

        update_issue(assignee_ids: [create(:user).id])

        expect(issue.reload.assignees).to eq([user3])
      end

      context "when issuable feature is private" do
        levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

        levels.each do |level|
          it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
            expect(NotificationService).not_to receive(:new)

            assignee = create(:user)
            project.update!(visibility_level: level)
            feature_visibility_attr = :"#{issue.model_name.plural}_access_level"
            project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

            expect { update_issue(assignee_ids: [assignee.id]) }.not_to change { issue.assignees }
          end
        end
      end

      it 'tracks the assignment events' do
        original_assignee = issue.assignees.first!

        update_issue(assignee_ids: [user2.id])
        update_issue(assignee_ids: [])
        update_issue(assignee_ids: [user3.id])

        expected_events = [
          have_attributes({
            issue_id: issue.id,
            user_id: original_assignee.id,
            action: 'remove'
          }),
          have_attributes({
            issue_id: issue.id,
            user_id: user2.id,
            action: 'add'
          }),
          have_attributes({
            issue_id: issue.id,
            user_id: user2.id,
            action: 'remove'
          }),
          have_attributes({
            issue_id: issue.id,
            user_id: user3.id,
            action: 'add'
          })
        ]

        expect(issue.assignment_events).to match_array(expected_events)
      end
    end

    context 'updating mentions' do
      let(:mentionable) { issue }

      include_examples 'updating mentions', described_class
    end

    context 'updating severity' do
      let(:opts) { { severity: 'low' } }

      shared_examples 'updates the severity' do |expected_severity|
        it 'has correct value' do
          update_issue(opts)

          expect(issue.severity).to eq(expected_severity)
        end

        it 'creates a system note' do
          expect(::IncidentManagement::AddSeveritySystemNoteWorker).to receive(:perform_async).with(issue.id, user.id)

          update_issue(opts)
        end

        it 'triggers webhooks' do
          expect(project.project_namespace).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), :issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), :incident_hooks)

          update_issue(opts)
        end
      end

      shared_examples 'does not change the severity' do
        it 'retains the original value' do
          expected_severity = issue.severity

          update_issue(opts)

          expect(issue.severity).to eq(expected_severity)
        end

        it 'does not trigger side-effects' do
          expect(::IncidentManagement::AddSeveritySystemNoteWorker).not_to receive(:perform_async)
          expect(project).not_to receive(:execute_hooks)
          expect(project).not_to receive(:execute_integrations)

          expect { update_issue(opts) }.not_to change(IssuableSeverity, :count)
        end
      end

      context 'on incidents' do
        let(:issue) { create(:incident, project: project) }

        context 'when severity has not been set previously' do
          it_behaves_like 'updates the severity', 'low'

          it 'creates a new record' do
            expect { update_issue(opts) }.to change(IssuableSeverity, :count).by(1)
          end

          context 'with unsupported severity value' do
            let(:opts) { { severity: 'unsupported-severity' } }

            it_behaves_like 'does not change the severity'
          end

          context 'with severity value defined but unchanged' do
            let(:opts) { { severity: IssuableSeverity::DEFAULT } }

            it_behaves_like 'does not change the severity'
          end

          context 'as guest' do
            let(:user) { guest }

            it_behaves_like 'does not change the severity'

            context 'and also author' do
              let(:issue) { create(:incident, project: project, author: user) }

              it_behaves_like 'does not change the severity'
            end

            context 'and also assignee' do
              let(:issue) { create(:incident, project: project, assignee_ids: [user.id]) }

              it_behaves_like 'does not change the severity'
            end
          end
        end

        context 'when severity has been set before' do
          before do
            create(:issuable_severity, issue: issue, severity: 'high')
          end

          it_behaves_like 'updates the severity', 'low'

          it 'does not create a new record' do
            expect { update_issue(opts) }.not_to change(IssuableSeverity, :count)
          end

          context 'with unsupported severity value' do
            let(:opts) { { severity: 'unsupported-severity' } }

            it_behaves_like 'updates the severity', IssuableSeverity::DEFAULT
          end

          context 'with severity value defined but unchanged' do
            let(:opts) { { severity: issue.severity } }

            it_behaves_like 'does not change the severity'
          end
        end
      end

      context 'when issue type is not incident' do
        it_behaves_like 'does not change the severity'
      end
    end

    context 'updating escalation status' do
      let(:opts) { { escalation_status: { status: 'acknowledged' } } }
      let(:escalation_update_class) { ::IncidentManagement::IssuableEscalationStatuses::AfterUpdateService }

      shared_examples 'updates the escalation status record' do |expected_status|
        let(:service_double) { instance_double(escalation_update_class) }

        it 'has correct value' do
          expect(escalation_update_class).to receive(:new).with(issue, user).and_return(service_double)
          expect(service_double).to receive(:execute)

          update_issue(opts)

          expect(issue.escalation_status.status_name).to eq(expected_status)
        end

        it 'triggers webhooks' do
          expect(project.project_namespace).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), :issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), :incident_hooks)

          update_issue(opts)
        end
      end

      shared_examples 'does not change the status record' do
        it 'retains the original value' do
          expected_status = issue.escalation_status&.status_name

          update_issue(opts)

          expect(issue.escalation_status&.status_name).to eq(expected_status)
        end

        it 'does not trigger side-effects' do
          expect(project).not_to receive(:execute_hooks)
          expect(project).not_to receive(:execute_integrations)

          update_issue(opts)
        end
      end

      context 'when issue is an incident' do
        let(:issue) { create(:incident, project: project) }

        context 'with an escalation status record' do
          before do
            create(:incident_management_issuable_escalation_status, issue: issue)
          end

          it_behaves_like 'updates the escalation status record', :acknowledged

          context 'with unsupported status value' do
            let(:opts) { { escalation_status: { status: 'unsupported-status' } } }

            it_behaves_like 'does not change the status record'
          end

          context 'with status value defined but unchanged' do
            let(:opts) { { escalation_status: { status: issue.escalation_status.status_name } } }

            it_behaves_like 'does not change the status record'
          end
        end

        context 'without an escalation status record' do
          it 'creates a new record' do
            expect { update_issue(opts) }.to change(::IncidentManagement::IssuableEscalationStatus, :count).by(1)
          end

          it_behaves_like 'updates the escalation status record', :acknowledged
        end
      end

      context 'when issue type is not incident' do
        it_behaves_like 'does not change the status record'
      end
    end

    context 'duplicate issue' do
      let(:canonical_issue) { create(:issue, project: project) }

      context 'invalid canonical_issue_id' do
        it 'does not call the duplicate service' do
          expect(Issues::DuplicateService).not_to receive(:new)

          update_issue(canonical_issue_id: 123456789)
        end
      end

      context 'valid canonical_issue_id' do
        it 'calls the duplicate service with both issues' do
          expect_next_instance_of(Issues::DuplicateService) do |service|
            expect(service).to receive(:execute).with(issue, canonical_issue)
          end

          update_issue(canonical_issue_id: canonical_issue.id)
        end
      end
    end

    context 'move issue to another project' do
      let(:target_project) { create(:project) }

      context 'valid project' do
        before do
          target_project.add_maintainer(user)
        end

        it 'calls the move service with the proper issue and project' do
          move_stub = instance_double(Issues::MoveService)
          allow(Issues::MoveService).to receive(:new).and_return(move_stub)
          allow(move_stub).to receive(:execute).with(issue, target_project).and_return(issue)

          expect(move_stub).to receive(:execute).with(issue, target_project)

          update_issue(target_project: target_project)
        end
      end
    end

    context 'clone an issue' do
      context 'valid project' do
        let(:target_project) { create(:project) }

        before do
          target_project.add_maintainer(user)
        end

        it 'calls the move service with the proper issue and project' do
          clone_stub = instance_double(Issues::CloneService)
          allow(Issues::CloneService).to receive(:new).and_return(clone_stub)
          allow(clone_stub).to receive(:execute).with(issue, target_project, with_notes: nil).and_return(issue)

          expect(clone_stub).to receive(:execute).with(issue, target_project, with_notes: nil)

          update_issue(target_clone_project: target_project)
        end
      end
    end

    context 'clone an issue with notes' do
      context 'valid project' do
        let(:target_project) { create(:project) }

        before do
          target_project.add_maintainer(user)
        end

        it 'calls the move service with the proper issue and project' do
          clone_stub = instance_double(Issues::CloneService)
          allow(Issues::CloneService).to receive(:new).and_return(clone_stub)
          allow(clone_stub).to receive(:execute).with(issue, target_project, with_notes: true).and_return(issue)

          expect(clone_stub).to receive(:execute).with(issue, target_project, with_notes: true)

          update_issue(target_clone_project: target_project, clone_with_notes: true)
        end
      end
    end

    context 'when moving an issue ' do
      it 'raises an error for invalid move ids' do
        opts = { move_between_ids: [9000, non_existing_record_id] }

        expect { described_class.new(container: issue.project, current_user: user, params: opts).execute(issue) }
            .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'issuable update service' do
      let(:open_issuable) { issue }
      let(:closed_issuable) { create(:closed_issue, :unchanged, project: project) }
    end

    context 'broadcasting issue assignee updates' do
      let(:update_params) { { assignee_ids: [user2.id] } }

      it 'triggers the GraphQL subscription' do
        expect(GraphqlTriggers).to receive(:issuable_assignees_updated).with(issue)

        update_issue(update_params)
      end

      context 'when assignee is not updated' do
        let(:update_params) { { title: 'Some other title' } }

        it 'does not trigger the GraphQL subscription' do
          expect(GraphqlTriggers).not_to receive(:issuable_assignees_updated).with(issue)

          update_issue(update_params)
        end
      end
    end

    it_behaves_like 'issuable record that supports quick actions' do
      let(:existing_issue) { create(:issue, project: project) }
      let(:issuable) { described_class.new(container: project, current_user: user, params: params).execute(existing_issue) }
    end

    it_behaves_like 'issuable record does not run quick actions when not editing description' do
      let(:label) { create(:label, project: project) }
      let(:assignee) { create(:user, maintainer_of: project) }
      let(:existing_issue) { create(:issue, project: project, description: old_description) }
      let(:updated_issuable) { described_class.new(container: project, current_user: user, params: params).execute(existing_issue) }
    end
  end
end
