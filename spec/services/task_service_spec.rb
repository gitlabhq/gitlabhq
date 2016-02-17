require 'spec_helper'

describe TaskService, services: true do
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
      it 'creates a task if assigned' do
        service.new_issue(issue, author)

        should_create_task(user: john_doe, target: issue, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        should_not_create_any_task { service.new_issue(unassigned_issue, author) }
      end

      it 'does not create a task if assignee is the current user' do
        should_not_create_any_task { service.new_issue(unassigned_issue, john_doe) }
      end

      it 'creates a task for each valid mentioned user' do
        service.new_issue(issue, author)

        should_create_task(user: michael, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: author, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: john_doe, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: stranger, target: issue, action: Task::MENTIONED)
      end
    end

    describe '#update_issue' do
      it 'marks pending tasks to the issue for the user as done' do
        pending_task = create(:task, :assigned, user: john_doe, project: project, target: issue, author: author)
        service.update_issue(issue, john_doe)

        expect(pending_task.reload).to be_done
      end

      it 'creates a task for each valid mentioned user' do
        service.update_issue(issue, author)

        should_create_task(user: michael, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: author, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: john_doe, target: issue, action: Task::MENTIONED)
        should_not_create_task(user: stranger, target: issue, action: Task::MENTIONED)
      end

      it 'does not create a task if user was already mentioned' do
        create(:task, :mentioned, user: michael, project: project, target: issue, author: author)

        should_not_create_any_task { service.update_issue(issue, author) }
      end
    end

    describe '#close_issue' do
      it 'marks related pending tasks to the target for the user as done' do
        first_task = create(:task, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_task = create(:task, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.close_issue(issue, john_doe)

        expect(first_task.reload).to be_done
        expect(second_task.reload).to be_done
      end
    end

    describe '#reassigned_issue' do
      it 'creates a pending task for new assignee' do
        unassigned_issue.update_attribute(:assignee, john_doe)
        service.reassigned_issue(unassigned_issue, author)

        should_create_task(user: john_doe, target: unassigned_issue, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        issue.update_attribute(:assignee, nil)

        should_not_create_any_task { service.reassigned_issue(issue, author) }
      end

      it 'does not create a task if new assignee is the current user' do
        unassigned_issue.update_attribute(:assignee, john_doe)

        should_not_create_any_task { service.reassigned_issue(unassigned_issue, john_doe) }
      end
    end

    describe '#new_note' do
      let!(:first_task) { create(:task, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let!(:second_task) { create(:task, :assigned, user: john_doe, project: project, target: issue, author: author) }
      let(:note) { create(:note, project: project, noteable: issue, author: john_doe, note: mentions) }
      let(:award_note) { create(:note, :award, project: project, noteable: issue, author: john_doe, note: 'thumbsup') }
      let(:system_note) { create(:system_note, project: project, noteable: issue) }

      it 'mark related pending tasks to the noteable for the note author as done' do
        first_task = create(:task, :assigned, user: john_doe, project: project, target: issue, author: author)
        second_task = create(:task, :assigned, user: john_doe, project: project, target: issue, author: author)

        service.new_note(note)

        expect(first_task.reload).to be_done
        expect(second_task.reload).to be_done
      end

      it 'mark related pending tasks to the noteable for the award note author as done' do
        service.new_note(award_note)

        expect(first_task.reload).to be_done
        expect(second_task.reload).to be_done
      end

      it 'does not mark related pending tasks it is a system note' do
        service.new_note(system_note)

        expect(first_task.reload).to be_pending
        expect(second_task.reload).to be_pending
      end

      it 'creates a task for each valid mentioned user' do
        service.new_note(note)

        should_create_task(user: michael, target: issue, author: john_doe, action: Task::MENTIONED, note: note)
        should_create_task(user: author, target: issue, author: john_doe, action: Task::MENTIONED, note: note)
        should_not_create_task(user: john_doe, target: issue, author: john_doe, action: Task::MENTIONED, note: note)
        should_not_create_task(user: stranger, target: issue, author: john_doe, action: Task::MENTIONED, note: note)
      end
    end
  end

  describe 'Merge Requests' do
    let(:mr_assigned) { create(:merge_request, source_project: project, author: author, assignee: john_doe, description: mentions) }
    let(:mr_unassigned) { create(:merge_request, source_project: project, author: author, assignee: nil) }

    describe '#new_merge_request' do
      it 'creates a pending task if assigned' do
        service.new_merge_request(mr_assigned, author)

        should_create_task(user: john_doe, target: mr_assigned, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        should_not_create_any_task { service.new_merge_request(mr_unassigned, author) }
      end

      it 'does not create a task if assignee is the current user' do
        should_not_create_any_task { service.new_merge_request(mr_unassigned, john_doe) }
      end

      it 'creates a task for each valid mentioned user' do
        service.new_merge_request(mr_assigned, author)

        should_create_task(user: michael, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: author, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: john_doe, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: stranger, target: mr_assigned, action: Task::MENTIONED)
      end
    end

    describe '#update_merge_request' do
      it 'marks pending tasks to the merge request for the user as done' do
        pending_task = create(:task, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        service.update_merge_request(mr_assigned, john_doe)

        expect(pending_task.reload).to be_done
      end

      it 'creates a task for each valid mentioned user' do
        service.update_merge_request(mr_assigned, author)

        should_create_task(user: michael, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: author, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: john_doe, target: mr_assigned, action: Task::MENTIONED)
        should_not_create_task(user: stranger, target: mr_assigned, action: Task::MENTIONED)
      end

      it 'does not create a task if user was already mentioned' do
        create(:task, :mentioned, user: michael, project: project, target: mr_assigned, author: author)

        should_not_create_any_task { service.update_merge_request(mr_assigned, author) }
      end
    end

    describe '#close_merge_request' do
      it 'marks related pending tasks to the target for the user as done' do
        first_task = create(:task, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        second_task = create(:task, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        service.close_merge_request(mr_assigned, john_doe)

        expect(first_task.reload).to be_done
        expect(second_task.reload).to be_done
      end
    end

    describe '#reassigned_merge_request' do
      it 'creates a pending task for new assignee' do
        mr_unassigned.update_attribute(:assignee, john_doe)
        service.reassigned_merge_request(mr_unassigned, author)

        should_create_task(user: john_doe, target: mr_unassigned, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        mr_assigned.update_attribute(:assignee, nil)

        should_not_create_any_task { service.reassigned_merge_request(mr_assigned, author) }
      end

      it 'does not create a task if new assignee is the current user' do
        mr_assigned.update_attribute(:assignee, john_doe)

        should_not_create_any_task { service.reassigned_merge_request(mr_assigned, john_doe) }
      end
    end

    describe '#merge_merge_request' do
      it 'marks related pending tasks to the target for the user as done' do
        first_task = create(:task, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        second_task = create(:task, :assigned, user: john_doe, project: project, target: mr_assigned, author: author)
        service.merge_merge_request(mr_assigned, john_doe)

        expect(first_task.reload).to be_done
        expect(second_task.reload).to be_done
      end
    end
  end

  def should_create_task(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Task.where(attributes).count).to eq 1
  end

  def should_not_create_task(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Task.where(attributes).count).to eq 0
  end

  def should_not_create_any_task
    expect { yield }.not_to change(Task, :count)
  end
end
