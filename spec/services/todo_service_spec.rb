# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodoService, feature_category: :notifications do
  include AfterNextHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:author) { create(:user, developer_of: project) }
  let_it_be(:assignee) { create(:user, developer_of: project) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:member) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:john_doe) { create(:user, developer_of: project) }
  let_it_be(:skipped) { create(:user, developer_of: project) }

  let(:skip_users) { [skipped] }
  let(:mentions) { 'FYI: ' + [author, assignee, john_doe, member, guest, non_member, admin, skipped].map(&:to_reference).join(' ') }
  let(:directly_addressed) { [author, assignee, john_doe, member, guest, non_member, admin, skipped].map(&:to_reference).join(' ') }
  let(:directly_addressed_and_mentioned) { member.to_reference + ", what do you think? cc: " + [guest, admin, skipped].map(&:to_reference).join(' ') }
  let(:service) { described_class.new }

  shared_examples 'reassigned target' do
    let(:additional_todo_attributes) { {} }

    it 'creates a pending todo for new assignee' do
      target_unassigned.assignees = [john_doe]
      service.send(described_method, target_unassigned, author)

      should_create_todo(
        user: john_doe,
        target: target_unassigned,
        action: Todo::ASSIGNED,
        **additional_todo_attributes
      )
    end

    it 'does not create a todo if unassigned' do
      target_assigned.assignees = []

      should_not_create_any_todo { service.send(described_method, target_assigned, author) }
    end

    it 'creates a todo if new assignee is the current user' do
      target_assigned.assignees = [john_doe]
      service.send(described_method, target_assigned, john_doe)

      should_create_todo(
        user: john_doe,
        target: target_assigned,
        author: john_doe,
        action: Todo::ASSIGNED,
        **additional_todo_attributes
      )
    end

    it 'does not create a todo for guests' do
      service.send(described_method, target_assigned, author)
      should_not_create_todo(user: guest, target: target_assigned, action: Todo::MENTIONED)
    end

    it 'does not create a directly addressed todo for guests' do
      service.send(described_method, addressed_target_assigned, author)

      should_not_create_todo(user: guest, target: addressed_target_assigned, action: Todo::DIRECTLY_ADDRESSED)
    end

    it 'does not create a todo if already assigned' do
      should_not_create_any_todo { service.send(described_method, target_assigned, author, [john_doe]) }
    end
  end

  shared_examples 'reassigned reviewable target' do
    context 'with no existing reviewers' do
      let(:assigned_reviewers) { [] }

      it 'creates a pending todo for new reviewer' do
        target.reviewers = [john_doe]
        service.send(described_method, target, author)

        should_create_todo(user: john_doe, target: target, action: Todo::REVIEW_REQUESTED)
      end
    end

    context 'with an existing reviewer' do
      let(:assigned_reviewers) { [john_doe] }

      it 'does not create a todo if unassigned' do
        target.reviewers = []

        should_not_create_any_todo { service.send(described_method, target, author) }
      end

      it 'creates a todo if new reviewer is the current user' do
        target.reviewers = [john_doe]
        service.send(described_method, target, john_doe)

        should_create_todo(user: john_doe, target: target, author: john_doe, action: Todo::REVIEW_REQUESTED)
      end

      it 'does not create a todo if already assigned' do
        should_not_create_any_todo { service.send(described_method, target, author, [john_doe]) }
      end
    end
  end

  describe 'Issues' do
    let(:issue) { create(:issue, project: project, author: author, description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:addressed_issue) { create(:issue, project: project, author: author, description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
    let(:assigned_issue) { create(:issue, project: project, assignees: [john_doe]) }
    let(:unassigned_issue) { create(:issue, project: project, assignees: []) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee], description: mentions) }
    let(:addressed_confident_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee], description: directly_addressed) }

    describe '#new_issue' do
      it 'creates a todo if assigned' do
        service.new_issue(assigned_issue, author)

        should_create_todo(user: john_doe, target: assigned_issue, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        should_not_create_any_todo { service.new_issue(unassigned_issue, author) }
      end

      it 'creates a todo if assignee is the current user' do
        unassigned_issue.assignees = [john_doe]
        service.new_issue(unassigned_issue, john_doe)

        should_create_todo(user: john_doe, target: unassigned_issue, author: john_doe, action: Todo::ASSIGNED)
      end

      it 'creates a todo for each valid mentioned user' do
        service.new_issue(issue, author)

        should_create_todo(user: member, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: author, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
      end

      it 'creates a directly addressed todo for each valid addressed user' do
        service.new_issue(addressed_issue, author)

        should_create_todo(user: member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: guest, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
      end

      it 'creates correct todos for each valid user based on the type of mention' do
        issue.update!(description: directly_addressed_and_mentioned)

        service.new_issue(issue, author)

        should_create_todo(user: member, target: issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
      end

      it 'does not create todo if user can not see the issue when issue is confidential' do
        service.new_issue(confidential_issue, john_doe)

        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::ASSIGNED)
        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
      end

      it 'does not create directly addressed todo if user cannot see the issue when issue is confidential' do
        service.new_issue(addressed_confident_issue, john_doe)

        should_create_todo(user: assignee, target: addressed_confident_issue, author: john_doe, action: Todo::ASSIGNED)
        should_create_todo(user: author, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: member, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: admin, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
      end

      context 'when a private group is mentioned' do
        let(:group)   { create(:group, :private) }
        let(:project) { create(:project, :private, group: group) }
        let(:issue)   { create(:issue, author: author, project: project, description: group.to_reference) }

        before do
          group.add_owner(author)
          group.add_member(member, Gitlab::Access::DEVELOPER)
          group.add_member(john_doe, Gitlab::Access::DEVELOPER)

          service.new_issue(issue, author)
        end

        it 'creates a todo for group members' do
          should_create_todo(user: member, target: issue)
          should_create_todo(user: john_doe, target: issue)
        end
      end

      context 'issue is an incident' do
        let(:issue) { create(:incident, project: project, assignees: [john_doe], author: author) }

        subject do
          service.new_issue(issue, author)
          should_create_todo(user: john_doe, target: issue, action: Todo::ASSIGNED)
        end

        it_behaves_like 'an incident management tracked event', :incident_management_incident_todo do
          let(:current_user) { john_doe }
        end

        it_behaves_like 'Snowplow event tracking with RedisHLL context' do
          let(:namespace) { project.namespace }
          let(:category) { described_class.to_s }
          let(:action) { 'incident_management_incident_todo' }
          let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
          let(:user) { john_doe }
        end
      end
    end

    describe '#update_issue' do
      it 'creates a todo for each valid mentioned user not included in skip_users' do
        service.update_issue(issue, author, skip_users)

        should_create_todo(user: member, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: author, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: issue, action: Todo::MENTIONED)
      end

      it 'creates a todo for each valid user not included in skip_users based on the type of mention' do
        issue.update!(description: directly_addressed_and_mentioned)

        service.update_issue(issue, author, skip_users)

        should_create_todo(user: member, target: issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: issue)
      end

      it 'creates a directly addressed todo for each valid addressed user not included in skip_users' do
        service.update_issue(addressed_issue, author, skip_users)

        should_create_todo(user: member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: guest, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: skipped, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
      end

      it 'does not create a todo if user was already mentioned and todo is pending' do
        stub_feature_flags(multiple_todos: false)

        create(:todo, :mentioned, user: member, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author, skip_users) }.not_to change(member.todos, :count)
      end

      it 'does not create a todo if user was already mentioned and todo is done' do
        create(:todo, :mentioned, :done, user: skipped, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
        stub_feature_flags(multiple_todos: false)

        create(:todo, :directly_addressed, user: member, project: project, target: addressed_issue, author: author)

        expect { service.update_issue(addressed_issue, author, skip_users) }.not_to change(member.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is done' do
        create(:todo, :directly_addressed, :done, user: skipped, project: project, target: addressed_issue, author: author)

        expect { service.update_issue(addressed_issue, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      it 'does not create todo if user can not see the issue when issue is confidential' do
        service.update_issue(confidential_issue, john_doe)

        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
      end

      it 'does not create a directly addressed todo if user can not see the issue when issue is confidential' do
        service.update_issue(addressed_confident_issue, john_doe)

        should_create_todo(user: author, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: assignee, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: member, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: admin, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
      end

      context 'issues with a task list' do
        it 'does not create todo when tasks are marked as completed' do
          issue.update!(description: "- [x] Task 1\n- [X] Task 2 #{mentions}")

          service.update_issue(issue, author)

          should_not_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: assignee, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: author, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: member, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
        end

        it 'does not create directly addressed todo when tasks are marked as completed' do
          addressed_issue.update!(description: "#{directly_addressed}\n- [x] Task 1\n- [x] Task 2\n")

          service.update_issue(addressed_issue, author)

          should_not_create_todo(user: admin, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: assignee, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: author, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: john_doe, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: non_member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        end

        it 'does not raise an error when description not change' do
          issue.update!(title: 'Sample')

          expect { service.update_issue(issue, author) }.not_to raise_error
        end
      end
    end

    describe '#close_issue' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.close_issue(issue, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end
    end

    describe '#destroy_target' do
      it 'refreshes the todos count cache for users with todos on the target' do
        create(:todo, state: :pending, target: issue, user: author, author: author, project: issue.project)
        create(:todo, state: :done, target: issue, user: assignee, author: assignee, project: issue.project)

        expect_next(Users::UpdateTodoCountCacheService, [author.id, assignee.id]).to receive(:execute)

        service.destroy_target(issue) { issue.destroy! }
      end

      it 'yields the target to the caller' do
        expect { |b| service.destroy_target(issue, &b) }
          .to yield_with_args(issue)
      end
    end

    describe '#resolve_todos_for_target' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.resolve_todos_for_target(issue, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      it 'calls GraphQL.issuable_todo_updated' do
        expect(GraphqlTriggers).to receive(:issuable_todo_updated).with(issue)

        service.resolve_todos_for_target(issue, john_doe)
      end

      describe 'cached counts' do
        it 'updates when todos change' do
          create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

          expect(john_doe.todos_done_count).to eq(0)
          expect(john_doe.todos_pending_count).to eq(1)
          expect(john_doe).to receive(:update_todos_count_cache).and_call_original

          service.resolve_todos_for_target(issue, john_doe)

          expect(john_doe.todos_done_count).to eq(1)
          expect(john_doe.todos_pending_count).to eq(0)
        end
      end
    end

    describe '#resolve_todos_with_attributes_for_target' do
      it 'marks related pending todos to the target for all the users as done' do
        first_todo = create(:todo, :assigned, user: member, project: project, target: issue, author: author)
        second_todo = create(:todo, :review_requested, user: john_doe, project: project, target: issue, author: author)
        another_todo = create(:todo, :assigned, user: john_doe, project: project, target: project, author: author)

        service.resolve_todos_with_attributes_for_target(issue, {})

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
        expect(another_todo.reload).to be_pending
      end

      it 'marks related only filtered pending todos to the target for all the users as done' do
        first_todo = create(:todo, :assigned, user: member, project: project, target: issue, author: author)
        second_todo = create(:todo, :review_requested, user: john_doe, project: project, target: issue, author: author)
        another_todo = create(:todo, :assigned, user: john_doe, project: project, target: project, author: author)

        service.resolve_todos_with_attributes_for_target(issue, { action: Todo::ASSIGNED })

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_pending
        expect(another_todo.reload).to be_pending
      end

      it 'fetches the pending todos with users preloaded' do
        expect(PendingTodosFinder).to receive(:new)
          .with(a_hash_including(preload_user_association: true)).and_call_original

        service.resolve_todos_with_attributes_for_target(issue, { action: Todo::ASSIGNED })
      end
    end

    describe '#new_note' do
      let!(:first_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }
      let(:note) { create(:note, project: project, noteable: issue, author: john_doe, note: mentions) }
      let(:confidential_note) { create(:note, :confidential, project: project, noteable: issue, author: john_doe, note: mentions) }
      let(:addressed_note) { create(:note, project: project, noteable: issue, author: john_doe, note: directly_addressed) }
      let(:note_on_commit) { create(:note_on_commit, project: project, author: john_doe, note: mentions) }
      let(:addressed_note_on_commit) { create(:note_on_commit, project: project, author: john_doe, note: directly_addressed) }
      let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project, note: mentions) }
      let(:addressed_note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project, note: directly_addressed) }
      let(:note_on_project_snippet) { create(:note_on_project_snippet, project: project, author: john_doe, note: mentions) }
      let(:system_note) { create(:system_note, project: project, noteable: issue) }

      it 'mark related pending todos to the noteable for the note author as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.new_note(note, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      it 'mark related pending todos to the discussion for the note author as done' do
        first_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: john_doe, note: "Discussion thread 1")
        first_discussion_reply = create(:discussion_note_on_issue, noteable: issue, project: issue.project, discussion_id: first_discussion_note.discussion_id)
        first_discussion_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author, note: first_discussion_reply)

        # Create a second discussion on the same issue
        second_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: john_doe, note: "Discussion thread 2")
        second_discussion_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author, note: second_discussion_note)

        first_discussion_reply_2 = create(:discussion_note_on_issue, project: project, noteable: issue, author: john_doe, note: mentions, discussion_id: first_discussion_note.discussion_id)
        service.new_note(first_discussion_reply_2, john_doe)

        expect(first_discussion_todo.reload).to be_done
        expect(second_discussion_todo.reload).not_to be_done
      end

      it 'does not mark related pending todos it is a system note' do
        service.new_note(system_note, john_doe)

        expect(first_todo.reload).to be_pending
        expect(second_todo.reload).to be_pending
      end

      it 'creates a todo for each valid mentioned user' do
        service.new_note(note, john_doe)

        should_create_todo(user: member, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_create_todo(user: guest, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_create_todo(user: author, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_create_todo(user: john_doe, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_not_create_todo(user: non_member, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
      end

      it 'creates a todo for each valid user based on the type of mention' do
        note.update!(note: directly_addressed_and_mentioned)

        service.new_note(note, john_doe)

        should_create_todo(user: member, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: note)
        should_not_create_todo(user: admin, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_create_todo(user: guest, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
      end

      it 'creates a directly addressed todo for each valid addressed user' do
        service.new_note(addressed_note, john_doe)

        should_create_todo(user: member, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note)
        should_create_todo(user: guest, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note)
        should_create_todo(user: author, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note)
        should_create_todo(user: john_doe, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note)
        should_not_create_todo(user: non_member, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note)
      end

      it 'does not create todo if user can not see the issue when leaving a note on a confidential issue' do
        service.new_note(note_on_confidential_issue, john_doe)

        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_not_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
      end

      it 'does not create a directly addressed todo if user can not see the issue when leaving a note on a confidential issue' do
        service.new_note(addressed_note_on_confidential_issue, john_doe)

        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_not_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
      end

      it 'does not create todo if user can not read confidential note' do
        service.new_note(confidential_note, john_doe)

        should_not_create_todo(user: non_member, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
        should_not_create_todo(user: guest, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
        should_create_todo(user: member, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
        should_create_todo(user: author, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
        should_create_todo(user: assignee, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
        should_create_todo(user: john_doe, target: issue, author: john_doe, action: Todo::MENTIONED, note: confidential_note)
      end

      context 'commits' do
        let(:base_commit_todo_attrs) { { target_id: nil, target_type: 'Commit', author: john_doe } }

        context 'leaving a note on a commit in a public project' do
          let(:project) { create(:project, :repository, :public) }

          it 'creates a todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::MENTIONED,
              note: note_on_commit,
              commit_id: note_on_commit.commit_id
            )

            service.new_note(note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_create_todo(expected_todo.merge(user: guest))
            should_create_todo(expected_todo.merge(user: non_member))
          end

          it 'creates a directly addressed todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::DIRECTLY_ADDRESSED,
              note: addressed_note_on_commit,
              commit_id: addressed_note_on_commit.commit_id
            )

            service.new_note(addressed_note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_create_todo(expected_todo.merge(user: guest))
            should_create_todo(expected_todo.merge(user: non_member))
          end
        end

        context 'leaving a note on a commit in a public project with private code' do
          let_it_be(:project) { create(:project, :repository, :public, :repository_private) }

          before_all do
            project.add_guest(guest)
            project.add_developer(author)
            project.add_developer(assignee)
            project.add_developer(member)
            project.add_developer(john_doe)
            project.add_developer(skipped)
          end

          it 'creates a todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::MENTIONED,
              note: note_on_commit,
              commit_id: note_on_commit.commit_id
            )

            service.new_note(note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_create_todo(expected_todo.merge(user: guest))
            should_not_create_todo(expected_todo.merge(user: non_member))
          end

          it 'creates a directly addressed todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::DIRECTLY_ADDRESSED,
              note: addressed_note_on_commit,
              commit_id: addressed_note_on_commit.commit_id
            )

            service.new_note(addressed_note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_create_todo(expected_todo.merge(user: guest))
            should_not_create_todo(expected_todo.merge(user: non_member))
          end
        end

        context 'leaving a note on a commit in a private project' do
          let_it_be(:project) { create(:project, :repository, :private) }

          before_all do
            project.add_guest(guest)
            project.add_developer(author)
            project.add_developer(assignee)
            project.add_developer(member)
            project.add_developer(john_doe)
            project.add_developer(skipped)
          end

          it 'creates a todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::MENTIONED,
              note: note_on_commit,
              commit_id: note_on_commit.commit_id
            )

            service.new_note(note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_not_create_todo(expected_todo.merge(user: guest))
            should_not_create_todo(expected_todo.merge(user: non_member))
          end

          it 'creates a directly addressed todo for each valid mentioned user' do
            expected_todo = base_commit_todo_attrs.merge(
              action: Todo::DIRECTLY_ADDRESSED,
              note: addressed_note_on_commit,
              commit_id: addressed_note_on_commit.commit_id
            )

            service.new_note(addressed_note_on_commit, john_doe)

            should_create_todo(expected_todo.merge(user: member))
            should_create_todo(expected_todo.merge(user: author))
            should_create_todo(expected_todo.merge(user: john_doe))
            should_not_create_todo(expected_todo.merge(user: guest))
            should_not_create_todo(expected_todo.merge(user: non_member))
          end
        end
      end

      it 'does not create todo when leaving a note on snippet' do
        should_not_create_any_todo { service.new_note(note_on_project_snippet, john_doe) }
      end
    end

    describe '#mark_todo' do
      it 'creates a todo from an issue' do
        service.mark_todo(unassigned_issue, author)

        should_create_todo(user: author, target: unassigned_issue, action: Todo::MARKED)
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter)
        .not_to receive(:track_work_item_todo_marked_action)
      end

      context 'when issue belongs to a group' do
        it 'creates a todo from an issue' do
          group_issue = create(:issue, :group_level, namespace: group)
          service.mark_todo(group_issue, group_issue.author)

          should_create_todo(
            user: group_issue.author,
            author: group_issue.author,
            target: group_issue,
            action: Todo::MARKED,
            project: nil,
            group: group
          )
          expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter)
          .not_to receive(:track_work_item_todo_marked_action)
        end
      end
    end

    describe '#todo_exists?' do
      it 'returns false when no todo exist for the given issuable' do
        expect(service.todo_exist?(unassigned_issue, author)).to be_falsy
      end

      it 'returns true when a todo exist for the given issuable' do
        service.mark_todo(unassigned_issue, author)

        expect(service.todo_exist?(unassigned_issue, author)).to be_truthy
      end
    end

    context 'when multiple_todos are enabled' do
      before do
        stub_feature_flags(multiple_todos: true)
      end

      it 'creates a MENTIONED todo even if user already has a pending MENTIONED todo' do
        create(:todo, :mentioned, user: member, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author) }.to change(member.todos, :count)
      end

      it 'creates a DIRECTLY_ADDRESSED todo even if user already has a pending DIRECTLY_ADDRESSED todo' do
        create(:todo, :directly_addressed, user: member, project: project, target: issue, author: author)

        issue.update!(description: "#{member.to_reference}, what do you think?")

        expect { service.update_issue(issue, author) }.to change(member.todos, :count)
      end

      it 'creates an ASSIGNED todo even if user already has a pending MARKED todo' do
        create(:todo, :marked, user: john_doe, project: project, target: assigned_issue, author: author)

        expect { service.reassigned_assignable(assigned_issue, author) }.to change(john_doe.todos, :count)
      end

      it 'does not create an ASSIGNED todo if user already has an ASSIGNED todo' do
        create(:todo, :assigned, user: john_doe, project: project, target: assigned_issue, author: author)

        expect { service.reassigned_assignable(assigned_issue, author) }.not_to change(john_doe.todos, :count)
      end

      it 'creates multiple todos if a user is assigned and mentioned in a new issue' do
        assigned_issue.description = mentions
        service.new_issue(assigned_issue, author)

        should_create_todo(user: john_doe, target: assigned_issue, action: Todo::ASSIGNED)
        should_create_todo(user: john_doe, target: assigned_issue, action: Todo::MENTIONED)
      end
    end
  end

  describe 'Work Items' do
    let(:work_item) { create(:work_item, :objective, project: project, author: author) }
    let(:activity_counter_class) { Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter }

    describe '#mark_todo' do
      it 'creates a todo from a work item' do
        expect(activity_counter_class).to receive(:track_work_item_mark_todo_action).with(author: author)

        service.mark_todo(work_item, author)

        should_create_todo(user: author, target: work_item, action: Todo::MARKED)
      end

      context 'when work item belongs to a group' do
        it 'creates a todo from a work item' do
          group_work_item = create(:work_item, :group_level, namespace: group)

          expect(activity_counter_class).to receive(:track_work_item_mark_todo_action).with(author: group_work_item.author)

          service.mark_todo(group_work_item, group_work_item.author)

          should_create_todo(
            user: group_work_item.author,
            author: group_work_item.author,
            target: group_work_item,
            action: Todo::MARKED,
            project: nil,
            group: group
          )
        end
      end
    end

    describe '#todo_exists?' do
      it 'returns false when no todo exist for the given work_item' do
        expect(service.todo_exist?(work_item, author)).to be_falsy
      end

      it 'returns true when a todo exist for the given work_item' do
        service.mark_todo(work_item, author)

        expect(service.todo_exist?(work_item, author)).to be_truthy
      end
    end

    describe '#resolve_todos_for_target' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: work_item, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: work_item, author: author)

        service.resolve_todos_for_target(work_item, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      describe 'cached counts' do
        it 'updates when todos change' do
          create(:todo, :assigned, user: john_doe, project: project, target: work_item, author: author)

          expect(john_doe.todos_done_count).to eq(0)
          expect(john_doe.todos_pending_count).to eq(1)
          expect(john_doe).to receive(:update_todos_count_cache).and_call_original

          service.resolve_todos_for_target(work_item, john_doe)

          expect(john_doe.todos_done_count).to eq(1)
          expect(john_doe.todos_pending_count).to eq(0)
        end
      end
    end
  end

  describe '#reassigned_assignable' do
    let(:described_method) { :reassigned_assignable }

    context 'assignable is a merge request' do
      it_behaves_like 'reassigned target' do
        let(:target_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_target_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:target_unassigned) { create(:merge_request, source_project: project, author: author, assignees: []) }
      end
    end

    context 'assignable is a project level issue' do
      it_behaves_like 'reassigned target' do
        let(:target_assigned) { create(:issue, project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_target_assigned) { create(:issue, project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:target_unassigned) { create(:issue, project: project, author: author, assignees: []) }
      end
    end

    context 'assignable is a project level work_item' do
      it_behaves_like 'reassigned target' do
        let(:target_assigned) { create(:work_item, project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_target_assigned) { create(:work_item, project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:target_unassigned) { create(:work_item, project: project, author: author, assignees: []) }
      end
    end

    context 'assignable is a group level issue' do
      it_behaves_like 'reassigned target' do
        let(:additional_todo_attributes) { { project: nil, group: group } }
        let(:target_assigned) { create(:issue, :group_level, namespace: group, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_target_assigned) { create(:issue, :group_level, namespace: group, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:target_unassigned) { create(:issue, :group_level, namespace: group, author: author, assignees: []) }
      end
    end

    context 'assignable is a group level work item' do
      it_behaves_like 'reassigned target' do
        let(:additional_todo_attributes) { { project: nil, group: group } }
        let(:target_assigned) { create(:work_item, :group_level, namespace: group, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_target_assigned) { create(:work_item, :group_level, namespace: group, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:target_unassigned) { create(:work_item, :group_level, namespace: group, author: author, assignees: []) }
      end
    end

    context 'assignable is an alert' do
      it_behaves_like 'reassigned target' do
        let(:target_assigned) { create(:alert_management_alert, project: project, assignees: [john_doe]) }
        let(:addressed_target_assigned) { create(:alert_management_alert, project: project, assignees: [john_doe]) }
        let(:target_unassigned) { create(:alert_management_alert, project: project, assignees: []) }
      end
    end
  end

  describe '#reassigned_reviewable' do
    let(:described_method) { :reassigned_reviewable }

    context 'reviewable is a merge request' do
      it_behaves_like 'reassigned reviewable target' do
        let(:assigned_reviewers) { [] }
        let(:target) { create(:merge_request, source_project: project, author: author, reviewers: assigned_reviewers) }
      end
    end
  end

  describe 'Merge Requests' do
    let(:mentioned_mr) { create(:merge_request, source_project: project, author: author, description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:addressed_mr) { create(:merge_request, source_project: project, author: author, description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
    let(:assigned_mr) { create(:merge_request, source_project: project, author: author, assignees: [john_doe]) }
    let(:unassigned_mr) { create(:merge_request, source_project: project, author: author, assignees: []) }

    describe '#new_merge_request' do
      it 'creates a pending todo if assigned' do
        service.new_merge_request(assigned_mr, author)

        should_create_todo(user: john_doe, target: assigned_mr, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        should_not_create_any_todo { service.new_merge_request(unassigned_mr, author) }
      end

      it 'creates a todo if assignee is the current user' do
        service.new_merge_request(assigned_mr, john_doe)

        should_create_todo(user: john_doe, target: assigned_mr, author: john_doe, action: Todo::ASSIGNED)
      end

      it 'creates a todo for each valid mentioned user' do
        service.new_merge_request(mentioned_mr, author)

        should_create_todo(user: member, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: mentioned_mr, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mentioned_mr, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mentioned_mr, action: Todo::MENTIONED)
      end

      it 'creates a todo for each valid user based on the type of mention' do
        mentioned_mr.update!(description: directly_addressed_and_mentioned)

        service.new_merge_request(mentioned_mr, author)

        should_create_todo(user: member, target: mentioned_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: admin, target: mentioned_mr, action: Todo::MENTIONED)
      end

      it 'creates a directly addressed todo for each valid addressed user' do
        service.new_merge_request(addressed_mr, author)

        should_create_todo(user: member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
      end
    end

    describe '#update_merge_request' do
      it 'creates a todo for each valid mentioned user not included in skip_users' do
        service.update_merge_request(mentioned_mr, author, skip_users)

        should_create_todo(user: member, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: mentioned_mr, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: mentioned_mr, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: mentioned_mr, action: Todo::MENTIONED)
      end

      it 'creates a todo for each valid user not included in skip_users based on the type of mention' do
        mentioned_mr.update!(description: directly_addressed_and_mentioned)

        service.update_merge_request(mentioned_mr, author, skip_users)

        should_create_todo(user: member, target: mentioned_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: admin, target: mentioned_mr, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: mentioned_mr)
      end

      it 'creates a directly addressed todo for each valid addressed user not included in skip_users' do
        service.update_merge_request(addressed_mr, author, skip_users)

        should_create_todo(user: member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: skipped, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
      end

      it 'does not create a todo if user was already mentioned and todo is pending' do
        stub_feature_flags(multiple_todos: false)

        create(:todo, :mentioned, user: member, project: project, target: mentioned_mr, author: author)

        expect { service.update_merge_request(mentioned_mr, author) }.not_to change(member.todos, :count)
      end

      it 'does not create a todo if user was already mentioned and todo is done' do
        create(:todo, :mentioned, :done, user: skipped, project: project, target: mentioned_mr, author: author)

        expect { service.update_merge_request(mentioned_mr, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
        stub_feature_flags(multiple_todos: false)

        create(:todo, :directly_addressed, user: member, project: project, target: addressed_mr, author: author)

        expect { service.update_merge_request(addressed_mr, author) }.not_to change(member.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is done' do
        create(:todo, :directly_addressed, user: skipped, project: project, target: addressed_mr, author: author)

        expect { service.update_merge_request(addressed_mr, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      context 'with a task list' do
        it 'does not create todo when tasks are marked as completed' do
          mentioned_mr.update!(description: "- [x] Task 1\n- [X] Task 2 #{mentions}")

          service.update_merge_request(mentioned_mr, author)

          should_not_create_todo(user: admin, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: assignee, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: author, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: john_doe, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: member, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: non_member, target: mentioned_mr, action: Todo::MENTIONED)
          should_not_create_todo(user: guest, target: mentioned_mr, action: Todo::MENTIONED)
        end

        it 'does not create directly addressed todo when tasks are marked as completed' do
          addressed_mr.update!(description: "#{directly_addressed}\n- [x] Task 1\n- [X] Task 2")

          service.update_merge_request(addressed_mr, author)

          should_not_create_todo(user: admin, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: assignee, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: author, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: john_doe, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: non_member, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: guest, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
        end

        it 'does not raise an error when description not change' do
          mentioned_mr.update!(title: 'Sample')

          expect { service.update_merge_request(mentioned_mr, author) }.not_to raise_error
        end
      end
    end

    describe '#close_merge_request' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)
        service.close_merge_request(mentioned_mr, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end
    end

    describe '#merge_merge_request' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)
        service.merge_merge_request(mentioned_mr, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      it 'does not create todo for guests' do
        service.merge_merge_request(mentioned_mr, john_doe)
        should_not_create_todo(user: guest, target: mentioned_mr, action: Todo::MENTIONED)
      end

      it 'does not create directly addressed todo for guests' do
        service.merge_merge_request(addressed_mr, john_doe)
        should_not_create_todo(user: guest, target: addressed_mr, action: Todo::DIRECTLY_ADDRESSED)
      end
    end

    describe '#new_award_emoji' do
      it 'marks related pending todos to the target for the user as done' do
        todo = create(:todo, user: john_doe, project: project, target: mentioned_mr, author: author)
        service.new_award_emoji(mentioned_mr, john_doe)

        expect(todo.reload).to be_done
      end

      it 'mark related pending todos to the discussion for the note author as done' do
        issue = create(:issue)

        # Issue #1
        # John Doe: "Discussion thread 1"
        #   Author: "@john_doe Reply to thread 1"
        #   _Todo generated for John Doe_
        #
        first_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: john_doe, note: "Discussion thread 1")
        first_discussion_reply = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: author, discussion_id: first_discussion_note.discussion_id, note: mentions)
        first_discussion_todo = create(:todo, user: john_doe, project: issue.project, target: issue, author: author, note: first_discussion_reply)

        # Issue #1
        # John Doe: "Discussion thread 2"
        #   Author: "@john_doe Reply to thread 2"
        #   _Todo generated for John Doe_
        #
        second_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: john_doe, note: "Discussion thread 2")
        second_discussion_reply = create(:discussion_note_on_issue, noteable: issue, project: issue.project, author: author, discussion_id: second_discussion_note.discussion_id, note: mentions)
        second_discussion_todo = create(:todo, user: john_doe, project: issue.project, target: issue, author: author, note: second_discussion_reply)

        service.new_award_emoji(first_discussion_reply, john_doe)

        expect(first_discussion_todo.reload).to be_done
        expect(second_discussion_todo.reload).not_to be_done
      end
    end

    describe '#ssh_key_expiring_soon' do
      let_it_be(:ssh_key) { create(:key, user: author) }

      context 'when given a single key' do
        it 'creates a pending todo for the user' do
          service.ssh_key_expiring_soon(ssh_key)

          should_create_todo(user: author, author: author, target: ssh_key, project: nil, action: Todo::SSH_KEY_EXPIRING_SOON)
        end
      end

      context 'when given an array of keys' do
        let_it_be(:ssh_key_of_member) { create(:key, user: member) }
        let_it_be(:ssh_key_of_guest) { create(:key, user: guest) }

        it 'creates a pending todo for each key with the correct user' do
          service.ssh_key_expiring_soon([ssh_key, ssh_key_of_member, ssh_key_of_guest])

          should_create_todo(user: author, author: author, target: ssh_key, project: nil, action: Todo::SSH_KEY_EXPIRING_SOON)
          should_create_todo(user: member, author: member, target: ssh_key_of_member, project: nil, action: Todo::SSH_KEY_EXPIRING_SOON)
          should_create_todo(user: guest, author: guest, target: ssh_key_of_guest, project: nil, action: Todo::SSH_KEY_EXPIRING_SOON)
        end
      end
    end

    describe '#ssh_key_expired' do
      let_it_be(:ssh_key) { create(:key, user: author) }

      context 'when given a single key' do
        it 'creates a pending todo for the user' do
          service.ssh_key_expired(ssh_key)

          should_create_todo(user: author, author: author, target: ssh_key, project: nil, action: Todo::SSH_KEY_EXPIRED)
        end
      end

      context 'when given an array of keys' do
        let_it_be(:ssh_key_of_member) { create(:key, user: member) }
        let_it_be(:ssh_key_of_guest) { create(:key, user: guest) }

        it 'creates a pending todo for each key with the correct user' do
          service.ssh_key_expired([ssh_key, ssh_key_of_member, ssh_key_of_guest])

          should_create_todo(user: author, author: author, target: ssh_key, project: nil, action: Todo::SSH_KEY_EXPIRED)
          should_create_todo(user: member, author: member, target: ssh_key_of_member, project: nil, action: Todo::SSH_KEY_EXPIRED)
          should_create_todo(user: guest, author: guest, target: ssh_key_of_guest, project: nil, action: Todo::SSH_KEY_EXPIRED)
        end
      end

      describe 'auto-resolve behavior' do
        let_it_be(:ssh_key_2) { create(:key, user: author) }
        let_it_be(:todo_for_expiring_key_1) { create(:todo, target: ssh_key, action: Todo::SSH_KEY_EXPIRING_SOON, user: author) }
        let_it_be(:todo_for_expiring_key_2) { create(:todo, target: ssh_key_2, action: Todo::SSH_KEY_EXPIRING_SOON, user: author) }

        it 'resolves the "expiring soon" todo for the same key' do
          service.ssh_key_expired(ssh_key)

          expect(todo_for_expiring_key_1.reload.state).to eq 'done'
        end

        it 'does not resolve "expiring soon" todos of other keys' do
          service.ssh_key_expired(ssh_key)

          expect(todo_for_expiring_key_2.state).to eq 'pending'
        end
      end
    end

    describe '#merge_request_build_failed' do
      let(:merge_participants) { [unassigned_mr.author, admin] }

      before do
        allow(unassigned_mr).to receive(:merge_participants).and_return(merge_participants)
      end

      it 'creates a pending todo for each merge_participant' do
        service.merge_request_build_failed(unassigned_mr)

        merge_participants.each do |participant|
          should_create_todo(user: participant, author: participant, target: unassigned_mr, action: Todo::BUILD_FAILED)
        end
      end
    end

    describe '#merge_request_push' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :build_failed, user: author, project: project, target: mentioned_mr, author: john_doe)
        second_todo = create(:todo, :build_failed, user: john_doe, project: project, target: mentioned_mr, author: john_doe)
        service.merge_request_push(mentioned_mr, author)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).not_to be_done
      end
    end

    describe '#merge_request_became_unmergeable' do
      let(:merge_participants) { [admin, create(:user)] }

      before do
        allow(unassigned_mr).to receive(:merge_participants).and_return(merge_participants)
      end

      it 'creates a pending todo for each merge_participant' do
        unassigned_mr.update!(merge_when_pipeline_succeeds: true, merge_user: admin)
        service.merge_request_became_unmergeable(unassigned_mr)

        merge_participants.each do |participant|
          should_create_todo(user: participant, author: participant, target: unassigned_mr, action: Todo::UNMERGEABLE)
        end
      end
    end

    describe '#mark_todo' do
      it 'creates a todo from a merge request' do
        service.mark_todo(unassigned_mr, author)

        should_create_todo(user: author, target: unassigned_mr, action: Todo::MARKED)
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter)
        .not_to receive(:track_work_item_todo_marked_action)
      end
    end

    describe '#new_note' do
      let_it_be(:project) { create(:project, :repository) }

      before_all do
        project.add_guest(guest)
        project.add_developer(author)
        project.add_developer(assignee)
        project.add_developer(member)
        project.add_developer(john_doe)
        project.add_developer(skipped)
      end

      let(:mention) { john_doe.to_reference }
      let(:diff_note_on_merge_request) { create(:diff_note_on_merge_request, project: project, noteable: unassigned_mr, author: author, note: "Hey #{mention}") }
      let(:addressed_diff_note_on_merge_request) { create(:diff_note_on_merge_request, project: project, noteable: unassigned_mr, author: author, note: "#{mention}, hey!") }
      let(:legacy_diff_note_on_merge_request) { create(:legacy_diff_note_on_merge_request, project: project, noteable: unassigned_mr, author: author, note: "Hey #{mention}") }

      it 'creates a todo for mentioned user on new diff note' do
        service.new_note(diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: unassigned_mr, author: author, action: Todo::MENTIONED, note: diff_note_on_merge_request)
      end

      it 'creates a directly addressed todo for addressed user on new diff note' do
        service.new_note(addressed_diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: unassigned_mr, author: author, action: Todo::DIRECTLY_ADDRESSED, note: addressed_diff_note_on_merge_request)
      end

      it 'creates a todo for mentioned user on legacy diff note' do
        service.new_note(legacy_diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: unassigned_mr, author: author, action: Todo::MENTIONED, note: legacy_diff_note_on_merge_request)
      end

      it 'does not create todo for guests' do
        note_on_merge_request = create :note_on_merge_request, project: project, noteable: mentioned_mr, note: mentions
        service.new_note(note_on_merge_request, author)

        should_not_create_todo(user: guest, target: mentioned_mr, action: Todo::MENTIONED)
      end
    end

    describe '#new_review' do
      it 'marks related pending todos to the target MR for the user as done' do
        first_todo = create(:todo, :pending, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)
        second_todo = create(:todo, :pending, :review_requested, user: john_doe, project: project, target: mentioned_mr, author: author)
        third_todo = create(:todo, :pending, :mentioned, user: john_doe, project: project, target: mentioned_mr, author: author)

        review = Review.new(merge_request: mentioned_mr)
        service.new_review(review, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
        expect(third_todo.reload).to be_done
      end

      it 'marks related pending todo to the target MR for the user as done when the multiple_todos feature is off' do
        stub_feature_flags(multiple_todos: false)

        only_todo = create(:todo, :pending, :assigned, user: john_doe, project: project, target: mentioned_mr, author: author)

        review = Review.new(merge_request: mentioned_mr)
        service.new_review(review, john_doe)

        expect(only_todo.reload).to be_done
      end
    end
  end

  describe 'Designs' do
    include DesignManagementTestHelpers

    let(:issue) { create(:issue, project: project) }
    let(:design) { create(:design, issue: issue) }

    before do
      enable_design_management

      project.add_guest(author)
      project.add_developer(john_doe)
    end

    let(:note) do
      build(
        :diff_note_on_design,
        noteable: design,
        author: author,
        note: "Hey #{john_doe.to_reference}"
      )
    end

    it 'creates a todo for mentioned user on new diff note' do
      service.new_note(note, author)

      should_create_todo(
        user: john_doe,
        target: design,
        action: Todo::MENTIONED,
        note: note
      )
    end
  end

  describe '#update_note' do
    let_it_be(:noteable) { create(:issue, project: project) }

    let(:note) { create(:note, project: project, note: mentions, noteable: noteable) }
    let(:addressed_note) { create(:note, project: project, note: directly_addressed.to_s, noteable: noteable) }

    it 'creates a todo for each valid mentioned user not included in skip_users' do
      service.update_note(note, author, skip_users)

      should_create_todo(user: member, target: noteable, action: Todo::MENTIONED)
      should_create_todo(user: guest, target: noteable, action: Todo::MENTIONED)
      should_create_todo(user: john_doe, target: noteable, action: Todo::MENTIONED)
      should_create_todo(user: author, target: noteable, action: Todo::MENTIONED)
      should_not_create_todo(user: non_member, target: noteable, action: Todo::MENTIONED)
      should_not_create_todo(user: skipped, target: noteable, action: Todo::MENTIONED)
    end

    it 'creates a todo for each valid user not included in skip_users based on the type of mention' do
      note.update!(note: directly_addressed_and_mentioned)

      service.update_note(note, author, skip_users)

      should_create_todo(user: member, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_create_todo(user: guest, target: noteable, action: Todo::MENTIONED)
      should_not_create_todo(user: admin, target: noteable, action: Todo::MENTIONED)
      should_not_create_todo(user: skipped, target: noteable)
    end

    it 'creates a directly addressed todo for each valid addressed user not included in skip_users' do
      service.update_note(addressed_note, author, skip_users)

      should_create_todo(user: member, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_create_todo(user: guest, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_create_todo(user: john_doe, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_create_todo(user: author, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_not_create_todo(user: non_member, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_not_create_todo(user: skipped, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
    end

    context 'users already have pending todos and the multiple_todos feature is off' do
      before do
        stub_feature_flags(multiple_todos: false)
      end

      let_it_be(:pending_todo_for_member) { create(:todo, :mentioned, user: member, project: project, target: noteable) }
      let_it_be(:pending_todo_for_guest) { create(:todo, :mentioned, user: guest, project: project, target: noteable) }
      let_it_be(:pending_todo_for_admin) { create(:todo, :mentioned, user: admin, project: project, target: noteable) }
      let_it_be(:note_mentioning_1_user) do
        create(:note, project: project, note: "FYI #{member.to_reference}", noteable: noteable)
      end

      let_it_be(:note_mentioning_3_users) do
        create(:note, project: project, note: 'FYI: ' + [member, guest, admin].map(&:to_reference).join(' '), noteable: noteable)
      end

      it 'does not create a todo if user was already mentioned and todo is pending' do
        expect { service.update_note(note_mentioning_1_user, author, skip_users) }.not_to change(member.todos, :count)
      end

      it 'does not create N+1 queries for pending todos' do
        # Excluding queries for user permissions because those do execute N+1 queries
        allow_any_instance_of(User).to receive(:can?).and_return(true)

        control = ActiveRecord::QueryRecorder.new { service.update_note(note_mentioning_1_user, author, skip_users) }

        expect { service.update_note(note_mentioning_3_users, author, skip_users) }.not_to exceed_query_limit(control)
      end
    end

    it 'does not create a todo if user was already mentioned and todo is done' do
      create(:todo, :mentioned, :done, user: skipped, project: project, target: noteable, author: author)

      expect { service.update_note(note, author, skip_users) }.not_to change(skipped.todos, :count)
    end

    it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
      stub_feature_flags(multiple_todos: false)

      create(:todo, :directly_addressed, user: member, project: project, target: noteable, author: author)

      expect { service.update_note(addressed_note, author, skip_users) }.not_to change(member.todos, :count)
    end

    it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is done' do
      create(:todo, :directly_addressed, :done, user: skipped, project: project, target: noteable, author: author)

      expect { service.update_note(addressed_note, author, skip_users) }.not_to change(skipped.todos, :count)
    end
  end

  it 'updates cached counts when a todo is created' do
    issue = create(:issue, project: project, assignees: [john_doe], author: author)

    expect_next(Users::UpdateTodoCountCacheService, [john_doe.id]).to receive(:execute)

    service.new_issue(issue, author)
  end

  shared_examples 'updating todos state' do |state, new_state, new_resolved_by = nil|
    let!(:first_todo) { create(:todo, state, user: john_doe) }
    let!(:second_todo) { create(:todo, state, user: john_doe) }
    let(:collection) { Todo.all }

    it 'updates related todos for the user with the new_state' do
      method_call

      expect(collection.all? { |todo| todo.reload.state?(new_state) }).to be_truthy
    end

    if new_resolved_by
      it 'updates resolution mechanism' do
        method_call

        expect(collection.all? { |todo| todo.reload.resolved_by_action == new_resolved_by }).to be_truthy
      end
    end

    it 'returns the updated ids' do
      expect(method_call).to match_array([first_todo.id, second_todo.id])
    end

    describe 'cached counts' do
      it 'updates when todos change' do
        expect(john_doe.todos.where(state: new_state).count).to eq(0)
        expect(john_doe.todos.where(state: state).count).to eq(2)
        expect(john_doe).to receive(:update_todos_count_cache).and_call_original

        method_call

        expect(john_doe.todos.where(state: new_state).count).to eq(2)
        expect(john_doe.todos.where(state: state).count).to eq(0)
      end
    end
  end

  describe '#resolve_todos' do
    it_behaves_like 'updating todos state', :pending, :done, 'mark_done' do
      subject(:method_call) do
        service.resolve_todos(collection, john_doe, resolution: :done, resolved_by_action: :mark_done)
      end
    end

    context 'when some to-dos were snoozed' do
      let!(:todo1) { create(:todo, :pending, user: john_doe) }
      let!(:todo2) { create(:todo, :pending, user: john_doe, snoozed_until: 1.hour.ago) }
      let!(:todo3) { create(:todo, :pending, user: john_doe, snoozed_until: 1.day.from_now) }

      it 'nullifies the `snoozed_until` column' do
        service.resolve_todos(Todo.all, john_doe, resolution: :done, resolved_by_action: :mark_done)

        expect(todo1.reload.snoozed_until).to be_nil
        expect(todo2.reload.snoozed_until).to be_nil
        expect(todo3.reload.snoozed_until).to be_nil
      end
    end
  end

  describe '#restore_todos' do
    it_behaves_like 'updating todos state', :done, :pending do
      subject(:method_call) do
        service.restore_todos(collection, john_doe)
      end
    end
  end

  describe '#resolve_todo' do
    let!(:todo) { create(:todo, :assigned, user: john_doe) }
    let!(:snoozed_todo) { create(:todo, :assigned, user: john_doe, snoozed_until: 1.day.from_now) }

    it 'marks pending todo as done' do
      expect do
        service.resolve_todo(todo, john_doe)
        todo.reload
      end.to change { todo.done? }.to(true)
    end

    it 'marks snoozed todo as done and nullifies `snoozed_until` column' do
      service.resolve_todo(snoozed_todo, john_doe)
      snoozed_todo.reload
      expect(snoozed_todo.done?).to be true
      expect(snoozed_todo.snoozed_until).to be_nil
    end

    it 'saves resolution mechanism' do
      expect do
        service.resolve_todo(todo, john_doe, resolved_by_action: :mark_done)
        todo.reload
      end.to change { todo.resolved_by_mark_done? }.to(true)
    end

    it 'calls GraphQL.issuable_todo_updated' do
      expect(GraphqlTriggers).to receive(:issuable_todo_updated).with(todo.target)

      service.resolve_todo(todo, john_doe)
    end

    context 'cached counts' do
      it 'updates when todos change' do
        expect(john_doe.todos_done_count).to eq(0)
        expect(john_doe.todos_pending_count).to eq(1)
        expect(john_doe).to receive(:update_todos_count_cache).and_call_original

        service.resolve_todo(todo, john_doe)

        expect(john_doe.todos_done_count).to eq(1)
        expect(john_doe.todos_pending_count).to eq(0)
      end
    end
  end

  describe '#resolve_access_request_todos' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:group_requester) { create(:group_member, :access_request, group: group, user: assignee) }
    let_it_be(:project_requester) { create(:project_member, :access_request, project: project, user: non_member) }
    let_it_be(:another_pending_todo) { create(:todo, state: :pending, user: john_doe) }
    # access request by another user
    let_it_be(:another_group_todo) do
      create(:todo, state: :pending, target: group, action: Todo::MEMBER_ACCESS_REQUESTED)
    end

    let_it_be(:another_project_todo) do
      create(:todo, state: :pending, target: project, action: Todo::MEMBER_ACCESS_REQUESTED)
    end

    it 'marks the todos for group access request handlers as done' do
      access_request_todos = [member, john_doe].map do |group_user|
        create(:todo,
          user: group_user,
          state: :pending,
          action: Todo::MEMBER_ACCESS_REQUESTED,
          author: group_requester.user,
          target: group
        )
      end

      expect do
        service.resolve_access_request_todos(group_requester)
      end.to change {
        Todo.pending.where(target: group).for_author(group_requester.user)
          .for_action(Todo::MEMBER_ACCESS_REQUESTED).count
      }.from(2).to(0)

      expect(access_request_todos.each(&:reload)).to all be_done
      expect(another_pending_todo.reload).not_to be_done
      expect(another_group_todo.reload).not_to be_done
    end

    it 'marks the todos for project access request handlers as done' do
      # The project has 1 owner already. Adding another owner here
      project.add_member(john_doe, Gitlab::Access::OWNER)

      access_request_todo = create(:todo,
        user: john_doe,
        state: :pending,
        action: Todo::MEMBER_ACCESS_REQUESTED,
        author: project_requester.user,
        target: project
      )

      expect do
        service.resolve_access_request_todos(project_requester)
      end.to change {
        Todo.pending.where(target: project).for_author(project_requester.user)
          .for_action(Todo::MEMBER_ACCESS_REQUESTED).count
      }.from(2).to(0) # The original owner todo was created with the pending access request

      expect(access_request_todo.reload).to be_done
      expect(another_pending_todo.reload).to be_pending
      expect(another_project_todo.reload).to be_pending
    end
  end

  describe '#restore_todo' do
    let!(:todo) { create(:todo, :done, user: john_doe) }

    it 'marks resolved todo as pending' do
      expect do
        service.restore_todo(todo, john_doe)
        todo.reload
      end.to change { todo.pending? }.to(true)
    end

    context 'cached counts' do
      it 'updates when todos change' do
        expect(john_doe.todos_done_count).to eq(1)
        expect(john_doe.todos_pending_count).to eq(0)
        expect(john_doe).to receive(:update_todos_count_cache).and_call_original

        service.restore_todo(todo, john_doe)

        expect(john_doe.todos_done_count).to eq(0)
        expect(john_doe.todos_pending_count).to eq(1)
      end
    end
  end

  describe '#create_request_review_todo' do
    let(:target) { create(:merge_request, author: author, source_project: project) }
    let(:reviewer) { create(:user) }

    it 'creates a todo for reviewer' do
      service.create_request_review_todo(target, author, reviewer)

      should_create_todo(user: reviewer, target: target, action: Todo::REVIEW_REQUESTED)
    end
  end

  describe '#create_member_access_request_todos' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }

    shared_examples 'member access request is raised' do
      context 'when the source has more than 10 owners' do
        it 'creates todos for 10 recently active source owners' do
          users = create_list(:user, 12, :with_sign_ins)
          users.each do |user|
            source.add_owner(user)
          end
          ten_most_recently_active_source_owners = users.sort_by(&:last_sign_in_at).last(10)
          excluded_source_owners = users - ten_most_recently_active_source_owners

          service.create_member_access_request_todos(requester1)

          ten_most_recently_active_source_owners.each do |owner|
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester1.user).count).to eq 1
          end

          excluded_source_owners.each do |owner|
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester1.user).count).to eq 0
          end
        end
      end

      context 'when total owners are less than 10' do
        it 'creates todos for all source owners' do
          users = create_list(:user, 4, :with_sign_ins)
          users.map do |user|
            source.add_owner(user)
          end

          service.create_member_access_request_todos(requester1)

          users.each do |owner|
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester1.user).count).to eq 1
          end
        end
      end

      context 'when multiple access requests are raised' do
        it 'creates todos for 10 recently active source owners for multiple requests' do
          users = create_list(:user, 12, :with_sign_ins)
          users.each do |user|
            source.add_owner(user)
          end
          ten_most_recently_active_source_owners = users.sort_by(&:last_sign_in_at).last(10)
          excluded_source_owners = users - ten_most_recently_active_source_owners

          service.create_member_access_request_todos(requester1)
          service.create_member_access_request_todos(requester2)

          ten_most_recently_active_source_owners.each do |owner|
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester1.user).count).to eq 1
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester2.user).count).to eq 1
          end

          excluded_source_owners.each do |owner|
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester1.user).count).to eq 0
            expect(Todo.where(user: owner, target: source, action: Todo::MEMBER_ACCESS_REQUESTED, author: requester2.user).count).to eq 0
          end
        end
      end
    end

    context 'when request is raised for group' do
      it_behaves_like 'member access request is raised' do
        let_it_be(:source) { create(:group, :public) }
        let_it_be(:requester1) { create(:group_member, :access_request, group: source, user: assignee) }
        let_it_be(:requester2) { create(:group_member, :access_request, group: source, user: non_member) }
      end
    end

    context 'when request is raised for project' do
      it_behaves_like 'member access request is raised' do
        let_it_be(:source) { create(:project, :public) }
        let_it_be(:requester1) { create(:project_member, :access_request, project: source, user: assignee) }
        let_it_be(:requester2) { create(:project_member, :access_request, project: source, user: non_member) }
      end
    end
  end

  def should_create_todo(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Todo.where(attributes).count).to eq 1
  end

  def should_not_create_todo(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Todo.where(attributes).count).to eq 0
  end

  def should_not_create_any_todo
    expect { yield }.not_to change(Todo, :count)
  end
end
