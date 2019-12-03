# frozen_string_literal: true

require 'spec_helper'

describe TodoService do
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:non_member) { create(:user) }
  let(:member) { create(:user) }
  let(:guest) { create(:user) }
  let(:admin) { create(:admin) }
  let(:john_doe) { create(:user) }
  let(:skipped) { create(:user) }
  let(:skip_users) { [skipped] }
  let(:project) { create(:project, :repository) }
  let(:mentions) { 'FYI: ' + [author, assignee, john_doe, member, guest, non_member, admin, skipped].map(&:to_reference).join(' ') }
  let(:directly_addressed) { [author, assignee, john_doe, member, guest, non_member, admin, skipped].map(&:to_reference).join(' ') }
  let(:directly_addressed_and_mentioned) { member.to_reference + ", what do you think? cc: " + [guest, admin, skipped].map(&:to_reference).join(' ') }
  let(:service) { described_class.new }

  before do
    project.add_guest(guest)
    project.add_developer(author)
    project.add_developer(assignee)
    project.add_developer(member)
    project.add_developer(john_doe)
    project.add_developer(skipped)
  end

  describe 'Issues' do
    let(:issue) { create(:issue, project: project, assignees: [john_doe], author: author, description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:addressed_issue) { create(:issue, project: project, assignees: [john_doe], author: author, description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
    let(:unassigned_issue) { create(:issue, project: project, assignees: []) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee], description: mentions) }
    let(:addressed_confident_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee], description: directly_addressed) }

    describe '#new_issue' do
      it 'creates a todo if assigned' do
        service.new_issue(issue, author)

        should_create_todo(user: john_doe, target: issue, action: Todo::ASSIGNED)
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
        should_not_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
      end

      it 'creates a directly addressed todo for each valid addressed user' do
        service.new_issue(addressed_issue, author)

        should_create_todo(user: member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: guest, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: john_doe, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
      end

      it 'creates correct todos for each valid user based on the type of mention' do
        issue.update(description: directly_addressed_and_mentioned)

        service.new_issue(issue, author)

        should_create_todo(user: member, target: issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
      end

      it 'does not create todo if user can not see the issue when issue is confidential' do
        service.new_issue(confidential_issue, john_doe)

        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::ASSIGNED)
        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
      end

      it 'does not create directly addressed todo if user cannot see the issue when issue is confidential' do
        service.new_issue(addressed_confident_issue, john_doe)

        should_create_todo(user: assignee, target: addressed_confident_issue, author: john_doe, action: Todo::ASSIGNED)
        should_create_todo(user: author, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: member, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: admin, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
      end

      context 'when a private group is mentioned' do
        let(:group)   { create(:group, :private) }
        let(:project) { create(:project, :private, group: group) }
        let(:issue)   { create(:issue, author: author, project: project, description: group.to_reference) }

        before do
          group.add_owner(author)
          group.add_user(member, Gitlab::Access::DEVELOPER)
          group.add_user(john_doe, Gitlab::Access::DEVELOPER)

          service.new_issue(issue, author)
        end

        it 'creates a todo for group members' do
          should_create_todo(user: member, target: issue)
          should_create_todo(user: john_doe, target: issue)
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
        issue.update(description: directly_addressed_and_mentioned)

        service.update_issue(issue, author, skip_users)

        should_create_todo(user: member, target: issue, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
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
        create(:todo, :mentioned, user: member, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author, skip_users) }.not_to change(member.todos, :count)
      end

      it 'does not create a todo if user was already mentioned and todo is done' do
        create(:todo, :mentioned, :done, user: skipped, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
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
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
      end

      it 'does not create a directly addressed todo if user can not see the issue when issue is confidential' do
        service.update_issue(addressed_confident_issue, john_doe)

        should_create_todo(user: author, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: assignee, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: member, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: admin, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_confident_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED)
      end

      context 'issues with a task list' do
        it 'does not create todo when tasks are marked as completed' do
          issue.update(description: "- [x] Task 1\n- [X] Task 2 #{mentions}")

          service.update_issue(issue, author)

          should_not_create_todo(user: admin, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: assignee, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: author, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: member, target: issue, action: Todo::MENTIONED)
          should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
        end

        it 'does not create directly addressed todo when tasks are marked as completed' do
          addressed_issue.update(description: "#{directly_addressed}\n- [x] Task 1\n- [x] Task 2\n")

          service.update_issue(addressed_issue, author)

          should_not_create_todo(user: admin, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: assignee, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: author, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: john_doe, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: non_member, target: addressed_issue, action: Todo::DIRECTLY_ADDRESSED)
        end

        it 'does not raise an error when description not change' do
          issue.update(title: 'Sample')

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
        create(:todo, target: issue, user: john_doe, author: john_doe, project: issue.project)

        expect_any_instance_of(User).to receive(:update_todos_count_cache).and_call_original

        service.destroy_target(issue) { }
      end

      it 'does not refresh the todos count cache for users with only done todos on the target' do
        create(:todo, :done, target: issue, user: john_doe, author: john_doe, project: issue.project)

        expect_any_instance_of(User).not_to receive(:update_todos_count_cache)

        service.destroy_target(issue) { }
      end

      it 'yields the target to the caller' do
        expect { |b| service.destroy_target(issue, &b) }
          .to yield_with_args(issue)
      end
    end

    describe '#mark_pending_todos_as_done' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.mark_pending_todos_as_done(issue, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      describe 'cached counts' do
        it 'updates when todos change' do
          create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

          expect(john_doe.todos_done_count).to eq(0)
          expect(john_doe.todos_pending_count).to eq(1)
          expect(john_doe).to receive(:update_todos_count_cache).and_call_original

          service.mark_pending_todos_as_done(issue, john_doe)

          expect(john_doe.todos_done_count).to eq(1)
          expect(john_doe.todos_pending_count).to eq(0)
        end
      end
    end

    shared_examples 'updating todos state' do |meth, state, new_state|
      let!(:first_todo) { create(:todo, state, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_todo) { create(:todo, state, user: john_doe, project: project, target: issue, author: author) }

      it 'updates related todos for the user with the new_state' do
        service.send(meth, collection, john_doe)

        expect(first_todo.reload.state?(new_state)).to be true
        expect(second_todo.reload.state?(new_state)).to be true
      end

      it 'returns the updated ids' do
        expect(service.send(meth, collection, john_doe)).to match_array([first_todo.id, second_todo.id])
      end

      describe 'cached counts' do
        it 'updates when todos change' do
          expect(john_doe.todos.where(state: new_state).count).to eq(0)
          expect(john_doe.todos.where(state: state).count).to eq(2)
          expect(john_doe).to receive(:update_todos_count_cache).and_call_original

          service.send(meth, collection, john_doe)

          expect(john_doe.todos.where(state: new_state).count).to eq(2)
          expect(john_doe.todos.where(state: state).count).to eq(0)
        end
      end
    end

    describe '#mark_todos_as_done' do
      it_behaves_like 'updating todos state', :mark_todos_as_done, :pending, :done do
        let(:collection) { Todo.all }
      end
    end

    describe '#mark_todos_as_done_by_ids' do
      it_behaves_like 'updating todos state', :mark_todos_as_done_by_ids, :pending, :done do
        let(:collection) { [first_todo, second_todo].map(&:id) }
      end
    end

    describe '#mark_todos_as_pending' do
      it_behaves_like 'updating todos state', :mark_todos_as_pending, :done, :pending do
        let(:collection) { Todo.all }
      end
    end

    describe '#mark_todos_as_pending_by_ids' do
      it_behaves_like 'updating todos state', :mark_todos_as_pending_by_ids, :done, :pending do
        let(:collection) { [first_todo, second_todo].map(&:id) }
      end
    end

    describe '#new_note' do
      let!(:first_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }
      let(:note) { create(:note, project: project, noteable: issue, author: john_doe, note: mentions) }
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
        note.update(note: directly_addressed_and_mentioned)

        service.new_note(note, john_doe)

        should_create_todo(user: member, target: issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: note)
        should_create_todo(user: admin, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
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
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
      end

      it 'does not create a directly addressed todo if user can not see the issue when leaving a note on a confidential issue' do
        service.new_note(addressed_note_on_confidential_issue, john_doe)

        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::DIRECTLY_ADDRESSED, note: addressed_note_on_confidential_issue)
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
          let(:project) { create(:project, :repository, :public, :repository_private) }

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
          let(:project) { create(:project, :repository, :private) }

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
      it 'creates a todo from a issue' do
        service.mark_todo(unassigned_issue, author)

        should_create_todo(user: author, target: unassigned_issue, action: Todo::MARKED)
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
  end

  describe '#reassigned_issuable' do
    shared_examples 'reassigned issuable' do
      it 'creates a pending todo for new assignee' do
        issuable_unassigned.assignees = [john_doe]
        service.reassigned_issuable(issuable_unassigned, author)

        should_create_todo(user: john_doe, target: issuable_unassigned, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        issuable_assigned.assignees = []

        should_not_create_any_todo { service.reassigned_issuable(issuable_assigned, author) }
      end

      it 'creates a todo if new assignee is the current user' do
        issuable_assigned.assignees = [john_doe]
        service.reassigned_issuable(issuable_assigned, john_doe)

        should_create_todo(user: john_doe, target: issuable_assigned, author: john_doe, action: Todo::ASSIGNED)
      end

      it 'does not create a todo for guests' do
        service.reassigned_issuable(issuable_assigned, author)
        should_not_create_todo(user: guest, target: issuable_assigned, action: Todo::MENTIONED)
      end

      it 'does not create a directly addressed todo for guests' do
        service.reassigned_issuable(addressed_issuable_assigned, author)
        should_not_create_todo(user: guest, target: addressed_issuable_assigned, action: Todo::DIRECTLY_ADDRESSED)
      end
    end

    context 'issuable is a merge request' do
      it_behaves_like 'reassigned issuable' do
        let(:issuable_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_issuable_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:issuable_unassigned) { create(:merge_request, source_project: project, author: author, assignees: []) }
      end
    end

    context 'issuable is an issue' do
      it_behaves_like 'reassigned issuable' do
        let(:issuable_assigned) { create(:issue, project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
        let(:addressed_issuable_assigned) { create(:issue, project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
        let(:issuable_unassigned) { create(:issue, project: project, author: author, assignees: []) }
      end
    end
  end

  describe 'Merge Requests' do
    let(:mr_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:addressed_mr_assigned) { create(:merge_request, source_project: project, author: author, assignees: [john_doe], description: "#{directly_addressed}\n- [ ] Task 1\n- [ ] Task 2") }
    let(:mr_unassigned) { create(:merge_request, source_project: project, author: author, assignees: []) }

    describe '#new_merge_request' do
      it 'creates a pending todo if assigned' do
        service.new_merge_request(mr_assigned, author)

        should_create_todo(user: john_doe, target: mr_assigned, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        should_not_create_any_todo { service.new_merge_request(mr_unassigned, author) }
      end

      it 'does not create a todo if assignee is the current user' do
        should_not_create_any_todo { service.new_merge_request(mr_unassigned, john_doe) }
      end

      it 'creates a todo for each valid mentioned user' do
        service.new_merge_request(mr_assigned, author)

        should_create_todo(user: member, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'creates a todo for each valid user based on the type of mention' do
        mr_assigned.update(description: directly_addressed_and_mentioned)

        service.new_merge_request(mr_assigned, author)

        should_create_todo(user: member, target: mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: admin, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'creates a directly addressed todo for each valid addressed user' do
        service.new_merge_request(addressed_mr_assigned, author)

        should_create_todo(user: member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: john_doe, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
      end
    end

    describe '#update_merge_request' do
      it 'creates a todo for each valid mentioned user not included in skip_users' do
        service.update_merge_request(mr_assigned, author, skip_users)

        should_create_todo(user: member, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'creates a todo for each valid user not included in skip_users based on the type of mention' do
        mr_assigned.update(description: directly_addressed_and_mentioned)

        service.update_merge_request(mr_assigned, author, skip_users)

        should_create_todo(user: member, target: mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: admin, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: skipped, target: mr_assigned)
      end

      it 'creates a directly addressed todo for each valid addressed user not included in skip_users' do
        service.update_merge_request(addressed_mr_assigned, author, skip_users)

        should_create_todo(user: member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: guest, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: john_doe, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_create_todo(user: author, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: non_member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        should_not_create_todo(user: skipped, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
      end

      it 'does not create a todo if user was already mentioned and todo is pending' do
        create(:todo, :mentioned, user: member, project: project, target: mr_assigned, author: author)

        expect { service.update_merge_request(mr_assigned, author) }.not_to change(member.todos, :count)
      end

      it 'does not create a todo if user was already mentioned and todo is done' do
        create(:todo, :mentioned, :done, user: skipped, project: project, target: mr_assigned, author: author)

        expect { service.update_merge_request(mr_assigned, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
        create(:todo, :directly_addressed, user: member, project: project, target: addressed_mr_assigned, author: author)

        expect { service.update_merge_request(addressed_mr_assigned, author) }.not_to change(member.todos, :count)
      end

      it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is done' do
        create(:todo, :directly_addressed, user: skipped, project: project, target: addressed_mr_assigned, author: author)

        expect { service.update_merge_request(addressed_mr_assigned, author, skip_users) }.not_to change(skipped.todos, :count)
      end

      context 'with a task list' do
        it 'does not create todo when tasks are marked as completed' do
          mr_assigned.update(description: "- [x] Task 1\n- [X] Task 2 #{mentions}")

          service.update_merge_request(mr_assigned, author)

          should_not_create_todo(user: admin, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: assignee, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: member, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: non_member, target: mr_assigned, action: Todo::MENTIONED)
          should_not_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
        end

        it 'does not create directly addressed todo when tasks are marked as completed' do
          addressed_mr_assigned.update(description: "#{directly_addressed}\n- [x] Task 1\n- [X] Task 2")

          service.update_merge_request(addressed_mr_assigned, author)

          should_not_create_todo(user: admin, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: assignee, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: author, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: john_doe, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: non_member, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
          should_not_create_todo(user: guest, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
        end

        it 'does not raise an error when description not change' do
          mr_assigned.update(title: 'Sample')

          expect { service.update_merge_request(mr_assigned, author) }.not_to raise_error
        end
      end
    end

    describe '#close_merge_request' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        service.close_merge_request(mr_assigned, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end
    end

    describe '#merge_merge_request' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        service.merge_merge_request(mr_assigned, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      it 'does not create todo for guests' do
        service.merge_merge_request(mr_assigned, john_doe)
        should_not_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'does not create directly addressed todo for guests' do
        service.merge_merge_request(addressed_mr_assigned, john_doe)
        should_not_create_todo(user: guest, target: addressed_mr_assigned, action: Todo::DIRECTLY_ADDRESSED)
      end
    end

    describe '#new_award_emoji' do
      it 'marks related pending todos to the target for the user as done' do
        todo = create(:todo, user: john_doe, project: project, target: mr_assigned, author: author)
        service.new_award_emoji(mr_assigned, john_doe)

        expect(todo.reload).to be_done
      end
    end

    describe '#merge_request_build_failed' do
      let(:merge_participants) { [mr_unassigned.author, admin] }

      before do
        allow(mr_unassigned).to receive(:merge_participants).and_return(merge_participants)
      end

      it 'creates a pending todo for each merge_participant' do
        service.merge_request_build_failed(mr_unassigned)

        merge_participants.each do |participant|
          should_create_todo(user: participant, author: participant, target: mr_unassigned, action: Todo::BUILD_FAILED)
        end
      end
    end

    describe '#merge_request_push' do
      it 'marks related pending todos to the target for the user as done' do
        first_todo = create(:todo, :build_failed, user: author, project: project, target: mr_assigned, author: john_doe)
        second_todo = create(:todo, :build_failed, user: john_doe, project: project, target: mr_assigned, author: john_doe)
        service.merge_request_push(mr_assigned, author)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).not_to be_done
      end
    end

    describe '#merge_request_became_unmergeable' do
      let(:merge_participants) { [admin, create(:user)] }

      before do
        allow(mr_unassigned).to receive(:merge_participants).and_return(merge_participants)
      end

      it 'creates a pending todo for each merge_participant' do
        mr_unassigned.update(merge_when_pipeline_succeeds: true, merge_user: admin)
        service.merge_request_became_unmergeable(mr_unassigned)

        merge_participants.each do |participant|
          should_create_todo(user: participant, author: participant, target: mr_unassigned, action: Todo::UNMERGEABLE)
        end
      end
    end

    describe '#mark_todo' do
      it 'creates a todo from a merge request' do
        service.mark_todo(mr_unassigned, author)

        should_create_todo(user: author, target: mr_unassigned, action: Todo::MARKED)
      end
    end

    describe '#new_note' do
      let(:project) { create(:project, :repository) }
      let(:mention) { john_doe.to_reference }
      let(:diff_note_on_merge_request) { create(:diff_note_on_merge_request, project: project, noteable: mr_unassigned, author: author, note: "Hey #{mention}") }
      let(:addressed_diff_note_on_merge_request) { create(:diff_note_on_merge_request, project: project, noteable: mr_unassigned, author: author, note: "#{mention}, hey!") }
      let(:legacy_diff_note_on_merge_request) { create(:legacy_diff_note_on_merge_request, project: project, noteable: mr_unassigned, author: author, note: "Hey #{mention}") }

      it 'creates a todo for mentioned user on new diff note' do
        service.new_note(diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: mr_unassigned, author: author, action: Todo::MENTIONED, note: diff_note_on_merge_request)
      end

      it 'creates a directly addressed todo for addressed user on new diff note' do
        service.new_note(addressed_diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: mr_unassigned, author: author, action: Todo::DIRECTLY_ADDRESSED, note: addressed_diff_note_on_merge_request)
      end

      it 'creates a todo for mentioned user on legacy diff note' do
        service.new_note(legacy_diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: mr_unassigned, author: author, action: Todo::MENTIONED, note: legacy_diff_note_on_merge_request)
      end

      it 'does not create todo for guests' do
        note_on_merge_request = create :note_on_merge_request, project: project, noteable: mr_assigned, note: mentions
        service.new_note(note_on_merge_request, author)

        should_not_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
      end
    end
  end

  describe '#update_note' do
    let(:noteable) { create(:issue, project: project) }
    let(:note) { create(:note, project: project, note: mentions, noteable: noteable) }
    let(:addressed_note) { create(:note, project: project, note: "#{directly_addressed}", noteable: noteable) }

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
      note.update(note: directly_addressed_and_mentioned)

      service.update_note(note, author, skip_users)

      should_create_todo(user: member, target: noteable, action: Todo::DIRECTLY_ADDRESSED)
      should_create_todo(user: guest, target: noteable, action: Todo::MENTIONED)
      should_create_todo(user: admin, target: noteable, action: Todo::MENTIONED)
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

    it 'does not create a todo if user was already mentioned and todo is pending' do
      create(:todo, :mentioned, user: member, project: project, target: noteable, author: author)

      expect { service.update_note(note, author, skip_users) }.not_to change(member.todos, :count)
    end

    it 'does not create a todo if user was already mentioned and todo is done' do
      create(:todo, :mentioned, :done, user: skipped, project: project, target: noteable, author: author)

      expect { service.update_note(note, author, skip_users) }.not_to change(skipped.todos, :count)
    end

    it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is pending' do
      create(:todo, :directly_addressed, user: member, project: project, target: noteable, author: author)

      expect { service.update_note(addressed_note, author, skip_users) }.not_to change(member.todos, :count)
    end

    it 'does not create a directly addressed todo if user was already mentioned or addressed and todo is done' do
      create(:todo, :directly_addressed, :done, user: skipped, project: project, target: noteable, author: author)

      expect { service.update_note(addressed_note, author, skip_users) }.not_to change(skipped.todos, :count)
    end
  end

  it 'updates cached counts when a todo is created' do
    issue = create(:issue, project: project, assignees: [john_doe], author: author, description: mentions)

    expect(john_doe.todos_pending_count).to eq(0)
    expect(john_doe).to receive(:update_todos_count_cache).and_call_original

    service.new_issue(issue, author)

    expect(Todo.where(user_id: john_doe.id, state: :pending).count).to eq 1
    expect(john_doe.todos_pending_count).to eq(1)
  end

  describe '#mark_todos_as_done' do
    let(:issue) { create(:issue, project: project, author: author, assignees: [john_doe]) }
    let(:another_issue) { create(:issue, project: project, author: author, assignees: [john_doe]) }

    it 'marks a relation of todos as done' do
      create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      todos = TodosFinder.new(john_doe, {}).execute
      expect { described_class.new.mark_todos_as_done(todos, john_doe) }
       .to change { john_doe.todos.done.count }.from(0).to(1)
    end

    it 'marks an array of todos as done' do
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      todos = TodosFinder.new(john_doe, {}).execute
      expect { described_class.new.mark_todos_as_done(todos, john_doe) }
        .to change { todo.reload.state }.from('pending').to('done')
    end

    it 'returns the ids of updated todos' do # Needed on API
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      todos = TodosFinder.new(john_doe, {}).execute
      expect(described_class.new.mark_todos_as_done(todos, john_doe)).to eq([todo.id])
    end

    context 'when some of the todos are done already' do
      let!(:first_todo) { create(:todo, :mentioned, user: john_doe, target: issue, project: project) }
      let!(:second_todo) { create(:todo, :mentioned, user: john_doe, target: another_issue, project: project) }

      it 'returns the ids of those still pending' do
        described_class.new.mark_pending_todos_as_done(issue, john_doe)

        expect(described_class.new.mark_todos_as_done(Todo.all, john_doe)).to eq([second_todo.id])
      end

      it 'returns an empty array if all are done' do
        described_class.new.mark_pending_todos_as_done(issue, john_doe)
        described_class.new.mark_pending_todos_as_done(another_issue, john_doe)

        expect(described_class.new.mark_todos_as_done(Todo.all, john_doe)).to eq([])
      end
    end
  end

  describe '#mark_todo_as_done' do
    it 'marks a todo done' do
      todo1 = create(:todo, :pending, user: john_doe)

      described_class.new.mark_todo_as_done(todo1, john_doe)

      expect(todo1.reload.state).to eq('done')
    end

    context 'when todo is already in state done' do
      let(:todo1) { create(:todo, :done, user: john_doe) }

      it 'does not update the todo' do
        expect { described_class.new.mark_todo_as_done(todo1, john_doe) }.not_to change(todo1.reload, :state)
      end

      it 'does not update cache count' do
        expect(john_doe).not_to receive(:update_todos_count_cache)

        described_class.new.mark_todo_as_done(todo1, john_doe)
      end
    end
  end

  describe '#mark_all_todos_as_done_by_user' do
    it 'marks all todos done' do
      todo1 = create(:todo, user: john_doe, state: :pending)
      todo2 = create(:todo, user: john_doe, state: :done)
      todo3 = create(:todo, user: john_doe, state: :pending)

      ids = described_class.new.mark_all_todos_as_done_by_user(john_doe)

      expect(ids).to contain_exactly(todo1.id, todo3.id)
      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('done')
      expect(todo3.reload.state).to eq('done')
    end
  end

  describe '#mark_todos_as_done_by_ids' do
    let(:issue) { create(:issue, project: project, author: author, assignees: [john_doe]) }
    let(:another_issue) { create(:issue, project: project, author: author, assignees: [john_doe]) }

    it 'marks an array of todo ids as done' do
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)
      another_todo = create(:todo, :mentioned, user: john_doe, target: another_issue, project: project)

      expect { described_class.new.mark_todos_as_done_by_ids([todo.id, another_todo.id], john_doe) }
        .to change { john_doe.todos.done.count }.from(0).to(2)
    end

    it 'marks a single todo id as done' do
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      expect { described_class.new.mark_todos_as_done_by_ids(todo.id, john_doe) }
        .to change { todo.reload.state }.from('pending').to('done')
    end

    it 'caches the number of todos of a user', :use_clean_rails_memory_store_caching do
      create(:todo, :mentioned, user: john_doe, target: issue, project: project)
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      described_class.new.mark_todos_as_done_by_ids(todo, john_doe)

      # Make sure no TodosFinder is inialized to perform counting
      expect(TodosFinder).not_to receive(:new)

      expect(john_doe.todos_done_count).to eq(1)
      expect(john_doe.todos_pending_count).to eq(1)
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
