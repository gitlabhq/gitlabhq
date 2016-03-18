require 'spec_helper'

describe TodoService, services: true do
  let(:author) { create(:user) }
  let(:john_doe) { create(:user, username: 'john_doe') }
  let(:michael) { create(:user, username: 'michael') }
  let(:stranger) { create(:user, username: 'stranger') }
  let(:project) { create(:project) }
  let(:mentions) { [author.to_reference, john_doe.to_reference, michael.to_reference, stranger.to_reference].join(' ') }
  let(:service) { described_class.new }

  before do
    project.team << [author, :developer]
    project.team << [john_doe, :developer]
    project.team << [michael, :developer]
  end

  describe 'Issues' do
    let(:issue) { create(:issue, project: project, assignee: john_doe, author: author, description: mentions) }
    let(:unassigned_issue) { create(:issue, project: project, assignee: nil) }

    describe '#new_issue' do
      it 'creates a todo if assigned' do
        service.new_issue(issue, author)

        should_create_todo(user: john_doe, target: issue, action: Todo::ASSIGNED)
      end

      it 'does not create a todo if unassigned' do
        should_not_create_any_todo { service.new_issue(unassigned_issue, author) }
      end

      it 'does not create a todo if assignee is the current user' do
        should_not_create_any_todo { service.new_issue(unassigned_issue, john_doe) }
      end

      it 'creates a todo for each valid mentioned user' do
        service.new_issue(issue, author)

        should_create_todo(user: michael, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: author, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: stranger, target: issue, action: Todo::MENTIONED)
      end
    end

    describe '#update_issue' do
      it 'creates a todo for each valid mentioned user' do
        service.update_issue(issue, author)

        should_create_todo(user: michael, target: issue, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: author, target: issue, action: Todo::MENTIONED)
        should_not_create_todo(user: stranger, target: issue, action: Todo::MENTIONED)
      end

      it 'does not create a todo if user was already mentioned' do
        create(:todo, :mentioned, user: michael, project: project, target: issue, author: author)

        expect { service.update_issue(issue, author) }.not_to change(michael.todos, :count)
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

      it 'does not create a todo if new assignee is the current user' do
        unassigned_issue.update_attribute(:assignee, john_doe)

        should_not_create_any_todo { service.reassigned_issue(unassigned_issue, john_doe) }
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
    end

    describe '#new_note' do
      let!(:first_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_todo) { create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let(:note) { create(:note, project: project, noteable: issue, author: john_doe, note: mentions) }
      let(:note_on_commit) { create(:note_on_commit, project: project, author: john_doe, note: mentions) }
      let(:note_on_project_snippet) { create(:note_on_project_snippet, project: project, author: john_doe, note: mentions) }
      let(:award_note) { create(:note, :award, project: project, noteable: issue, author: john_doe, note: 'thumbsup') }
      let(:system_note) { create(:system_note, project: project, noteable: issue) }

      it 'mark related pending todos to the noteable for the note author as done' do
        first_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_todo = create(:todo, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.new_note(note, john_doe)

        expect(first_todo.reload).to be_done
        expect(second_todo.reload).to be_done
      end

      it 'mark related pending todos to the noteable for the award note author as done' do
        service.new_note(award_note, john_doe)

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

        should_create_todo(user: michael, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_create_todo(user: author, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_not_create_todo(user: john_doe, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
        should_not_create_todo(user: stranger, target: issue, author: john_doe, action: Todo::MENTIONED, note: note)
      end

      it 'does not create todo when leaving a note on commit' do
        should_not_create_any_todo { service.new_note(note_on_commit, john_doe) }
      end

      it 'does not create todo when leaving a note on snippet' do
        should_not_create_any_todo { service.new_note(note_on_project_snippet, john_doe) }
      end
    end
  end

  describe 'Merge Requests' do
    let(:mr_assigned) { create(:merge_request, source_project: project, author: author, assignee: john_doe, description: mentions) }
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

        should_create_todo(user: michael, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: stranger, target: mr_assigned, action: Todo::MENTIONED)
      end
    end

    describe '#update_merge_request' do
      it 'creates a todo for each valid mentioned user' do
        service.update_merge_request(mr_assigned, author)

        should_create_todo(user: michael, target: mr_assigned, action: Todo::MENTIONED)
        should_create_todo(user: john_doe, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: author, target: mr_assigned, action: Todo::MENTIONED)
        should_not_create_todo(user: stranger, target: mr_assigned, action: Todo::MENTIONED)
      end

      it 'does not create a todo if user was already mentioned' do
        create(:todo, :mentioned, user: michael, project: project, target: mr_assigned, author: author)

        expect { service.update_merge_request(mr_assigned, author) }.not_to change(michael.todos, :count)
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

      it 'does not create a todo if new assignee is the current user' do
        mr_assigned.update_attribute(:assignee, john_doe)

        should_not_create_any_todo { service.reassigned_merge_request(mr_assigned, john_doe) }
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
