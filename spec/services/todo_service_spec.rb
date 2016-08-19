require 'spec_helper'

describe TodoService, services: true do
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:non_member) { create(:user) }
  let(:member) { create(:user) }
  let(:guest) { create(:user) }
  let(:admin) { create(:admin) }
  let(:john_doe) { create(:user) }
  let(:project) { create(:project) }
  let(:mentions) { [author, assignee, john_doe, member, guest, non_member, admin].map(&:to_reference).join(' ') }
  let(:service) { described_class.new }

  before do
    project.team << [guest, :guest]
    project.team << [author, :developer]
    project.team << [member, :developer]
    project.team << [john_doe, :developer]
  end

  describe 'Issues' do
    let(:issue) { create(:issue, project: project, assignee: john_doe, author: author, description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:unassigned_issue) { create(:issue, project: project, assignee: nil) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignee: assignee, description: mentions) }

    describe '#new_issue' do
      it 'creates a todo if assigned' do
        service.new_issue(issue, author)

        should_create_todo(user: john_doe, target: issue, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        should_not_create_any_todo { service.new_issue(unassigned_issue, author) }
      end

      it 'creates a todo if assignee is the current user' do
        unassigned_issue.update_attribute(:assignee, john_doe)
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

      it 'does not create todo if user can not see the issue when issue is confidential' do
        service.new_issue(confidential_issue, john_doe)

        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::ASSIGNED)
        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED)
      end

      context 'when a private group is mentioned' do
        let(:group) { create :group, :private }
        let(:project) { create :project, :private, group: group }
        let(:issue) { create :issue, author: author, project: project, description: group.to_reference }

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
      it 'creates a todo for each valid mentioned user' do
        service.update_issue(issue, author)

        should_create_todo(user: member, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: author, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: issue, action: Todo::MENTIONED)
      end

      it 'does not create a todo if user was already mentioned' do
        create(:todo, :mentioned, user: member, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author) }.not_to change(member.todos, :count)
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

    describe '#reassigned_issue' do
      it 'creates a pending todo for new assignee' do
        unassigned_issue.update_attribute(:assignee, john_doe)
        service.reassigned_issue(unassigned_issue, author)

        should_create_todo(user: john_doe, target: unassigned_issue, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        issue.update_attribute(:assignee, nil)

        should_not_create_any_todo { service.reassigned_issue(issue, author) }
      end

      it 'creates a todo if new assignee is the current user' do
        unassigned_issue.update_attribute(:assignee, john_doe)
        service.reassigned_issue(unassigned_issue, john_doe)

        should_create_todo(user: john_doe, target: unassigned_issue, author: john_doe, action: Todo::ASSIGNED)
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

    describe '#mark_todos_as_done' do
      it 'marks related todos for the user as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.mark_todos_as_done([first_todo, second_todo], john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      describe 'cached counts' do
        it 'updates when todos change' do
          todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

          expect(john_doe.todos_done_count).to eq(0)
          expect(john_doe.todos_pending_count).to eq(1)
          expect(john_doe).to receive(:update_todos_count_cache).and_call_original

          service.mark_todos_as_done([todo], john_doe)

          expect(john_doe.todos_done_count).to eq(1)
          expect(john_doe.todos_pending_count).to eq(0)
        end
      end
    end

    describe '#new_note' do
      let!(:first_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignee: assignee) }
      let(:note) { create(:note, project: project, noteable: issue, author: john_doe, note: mentions) }
      let(:note_on_commit) { create(:note_on_commit, project: project, author: john_doe, note: mentions) }
      let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project, note: mentions) }
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

      it 'does not create todo if user can not see the issue when leaving a note on a confidential issue' do
        service.new_note(note_on_confidential_issue, john_doe)

        should_create_todo(user: author, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: assignee, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: member, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: admin, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_not_create_todo(user: guest, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
        should_create_todo(user: john_doe, target: confidential_issue, author: john_doe, action: Todo::MENTIONED, note: note_on_confidential_issue)
      end

      it 'creates a todo for each valid mentioned user when leaving a note on commit' do
        service.new_note(note_on_commit, john_doe)

        should_create_todo(user: member, target_id: nil, target_type: 'Commit', commit_id: note_on_commit.commit_id, author: john_doe, action: Todo::MENTIONED, note: note_on_commit)
        should_create_todo(user: author, target_id: nil, target_type: 'Commit', commit_id: note_on_commit.commit_id, author: john_doe, action: Todo::MENTIONED, note: note_on_commit)
        should_create_todo(user: john_doe, target_id: nil, target_type: 'Commit', commit_id: note_on_commit.commit_id, author: john_doe, action: Todo::MENTIONED, note: note_on_commit)
        should_not_create_todo(user: non_member, target_id: nil, target_type: 'Commit', commit_id: note_on_commit.commit_id, author: john_doe, action: Todo::MENTIONED, note: note_on_commit)
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
  end

  describe 'Merge Requests' do
    let(:mr_assigned) { create(:merge_request, source_project: project, author: author, assignee: john_doe, description: "- [ ] Task 1\n- [ ] Task 2 #{mentions}") }
    let(:mr_unassigned) { create(:merge_request, source_project: project, author: author, assignee: nil) }

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
        should_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mr_assigned, action: Todo::MENTIONED)
      end

      context 'when the merge request has approvers' do
        let(:approver_1) { create(:user) }
        let(:approver_2) { create(:user) }
        let(:approver_3) { create(:user) }
        let(:approver_mentions) { [john_doe, approver_1].map(&:to_reference).join(' ') }
        let(:mr_approvers) { create(:merge_request, source_project: project, author: author, description: approver_mentions) }

        before do
          project.team << [approver_1, :developer]
          project.team << [approver_2, :developer]
          project.team << [approver_3, :developer]

          create(:approver, user: approver_1, target: mr_approvers)
          create(:approver, user: approver_2, target: mr_approvers)

          service.new_merge_request(mr_approvers, author)
        end

        it 'creates a todo for each approver' do
          should_create_todo(user: approver_1, target: mr_approvers, action: Todo::APPROVAL_REQUIRED)
          should_create_todo(user: approver_2, target: mr_approvers, action: Todo::APPROVAL_REQUIRED)
          should_not_create_todo(user: approver_3, target: mr_approvers, action: Todo::APPROVAL_REQUIRED)
        end

        it 'creates a todo for each valid mentioned user' do
          should_create_todo(user: john_doe, target: mr_approvers, action: Todo::MENTIONED)
          should_not_create_todo(user: approver_1, target: mr_approvers, action: Todo::MENTIONED)
        end
      end
    end

    describe '#update_merge_request' do
      it 'creates a todo for each valid mentioned user' do
        service.update_merge_request(mr_assigned, author)

        should_create_todo(user: member, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: guest, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: non_member, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'does not create a todo if user was already mentioned' do
        create(:todo, :mentioned, user: member, project: project, target: mr_assigned, author: author)

        expect { service.update_merge_request(mr_assigned, author) }.not_to change(member.todos, :count)
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

    describe '#reassigned_merge_request' do
      it 'creates a pending todo for new assignee' do
        mr_unassigned.update_attribute(:assignee, john_doe)
        service.reassigned_merge_request(mr_unassigned, author)

        should_create_todo(user: john_doe, target: mr_unassigned, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        mr_assigned.update_attribute(:assignee, nil)

        should_not_create_any_todo { service.reassigned_merge_request(mr_assigned, author) }
      end

      it 'creates a todo if new assignee is the current user' do
        mr_assigned.update_attribute(:assignee, john_doe)
        service.reassigned_merge_request(mr_assigned, john_doe)

        should_create_todo(user: john_doe, target: mr_assigned, author: john_doe, action: Todo::ASSIGNED)
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
    end

    describe '#new_award_emoji' do
      it 'marks related pending todos to the target for the user as done' do
        todo = create(:todo, user: john_doe, project: project, target: mr_assigned, author: author)
        service.new_award_emoji(mr_assigned, john_doe)

        expect(todo.reload).to be_done
      end
    end

    describe '#merge_request_build_failed' do
      it 'creates a pending todo for the merge request author' do
        service.merge_request_build_failed(mr_unassigned)

        should_create_todo(user: author, target: mr_unassigned, action: Todo::BUILD_FAILED)
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

    describe '#mark_todo' do
      it 'creates a todo from a merge request' do
        service.mark_todo(mr_unassigned, author)

        should_create_todo(user: author, target: mr_unassigned, action: Todo::MARKED)
      end
    end

    describe '#new_note' do
      let(:mention) { john_doe.to_reference }
      let(:diff_note_on_merge_request) { create(:diff_note_on_merge_request, project: project, noteable: mr_unassigned, author: author, note: "Hey #{mention}") }
      let(:legacy_diff_note_on_merge_request) { create(:legacy_diff_note_on_merge_request, project: project, noteable: mr_unassigned, author: author, note: "Hey #{mention}") }

      it 'creates a todo for mentioned user on new diff note' do
        service.new_note(diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: mr_unassigned, author: author, action: Todo::MENTIONED, note: diff_note_on_merge_request)
      end

      it 'creates a todo for mentioned user on legacy diff note' do
        service.new_note(legacy_diff_note_on_merge_request, author)

        should_create_todo(user: john_doe, target: mr_unassigned, author: author, action: Todo::MENTIONED, note: legacy_diff_note_on_merge_request)
      end
    end
  end

  it 'updates cached counts when a todo is created' do
    issue = create(:issue, project: project, assignee: john_doe, author: author, description: mentions)

    expect(john_doe.todos_pending_count).to eq(0)
    expect(john_doe).to receive(:update_todos_count_cache)

    service.new_issue(issue, author)

    expect(Todo.where(user_id: john_doe.id, state: :pending).count).to eq 1
    expect(john_doe.todos_pending_count).to eq(1)
  end

  describe '#mark_todos_as_done' do
    let(:issue) { create(:issue, project: project, author: author, assignee: john_doe) }

    it 'marks a relation of todos as done' do
      create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      todos = TodosFinder.new(john_doe, {}).execute
      expect { TodoService.new.mark_todos_as_done(todos, john_doe) }
       .to change { john_doe.todos.done.count }.from(0).to(1)
    end

    it 'marks an array of todos as done' do
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      expect { TodoService.new.mark_todos_as_done([todo], john_doe) }
        .to change { todo.reload.state }.from('pending').to('done')
    end

    it 'returns the number of updated todos' do # Needed on API
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)

      expect(TodoService.new.mark_todos_as_done([todo], john_doe)).to eq(1)
    end

    it 'caches the number of todos of a user', :caching do
      create(:todo, :mentioned, user: john_doe, target: issue, project: project)
      todo = create(:todo, :mentioned, user: john_doe, target: issue, project: project)
      TodoService.new.mark_todos_as_done([todo], john_doe)

      expect_any_instance_of(TodosFinder).not_to receive(:execute)

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
