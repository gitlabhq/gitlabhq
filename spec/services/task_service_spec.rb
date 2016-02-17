require 'spec_helper'

describe TaskService, services: true do
  let(:author) { create(:user) }
  let(:john_doe) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { described_class.new }

  before do
    project.team << [author, :developer]
    project.team << [john_doe, :developer]
  end

  describe 'Issues' do
    let(:assigned_issue) { create(:issue, project: project, assignee: john_doe) }
    let(:unassigned_issue) { create(:issue, project: project, assignee: nil) }

    describe '#new_issue' do
      it 'creates a pending task if assigned' do
        service.new_issue(assigned_issue, author)

        is_expected_to_create_pending_task(user: john_doe, target: assigned_issue, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        is_expected_to_not_create_task { service.new_issue(unassigned_issue, author) }
      end

      it 'does not create a task if assignee is the current user' do
        is_expected_to_not_create_task { service.new_issue(unassigned_issue, john_doe) }
      end
    end

    describe '#close_issue' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      it 'marks related pending tasks to the target for the user as done' do
        service.close_issue(assigned_issue, john_doe)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end
    end

    describe '#reassigned_issue' do
      it 'creates a pending task for new assignee' do
        unassigned_issue.update_attribute(:assignee, john_doe)
        service.reassigned_issue(unassigned_issue, author)

        is_expected_to_create_pending_task(user: john_doe, target: unassigned_issue, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        assigned_issue.update_attribute(:assignee, nil)

        is_expected_to_not_create_task { service.reassigned_issue(assigned_issue, author) }
      end
    end

    describe '#mark_pending_tasks_as_done' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      it 'marks related pending tasks to the target for the user as done' do
        service.mark_pending_tasks_as_done(assigned_issue, john_doe)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end
    end

    describe '#new_note' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      let(:note) { create(:note, project: project, noteable: assigned_issue, author: john_doe) }
      let(:award_note) { create(:note, :award, project: project, noteable: assigned_issue, author: john_doe, note: 'thumbsup') }
      let(:system_note) { create(:system_note, project: project, noteable: assigned_issue) }

      it 'mark related pending tasks to the noteable for the note author as done' do
        service.new_note(note)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end

      it 'mark related pending tasks to the noteable for the award note author as done' do
        service.new_note(award_note)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end

      it 'does not mark related pending tasks it is a system note' do
        service.new_note(system_note)

        expect(first_pending_task.reload).to be_pending
        expect(second_pending_task.reload).to be_pending
      end
    end
  end

  describe 'Merge Requests' do
    let(:mr_assigned) { create(:merge_request, source_project: project, assignee: john_doe) }
    let(:mr_unassigned) { create(:merge_request, source_project: project, assignee: nil) }

    describe '#new_merge_request' do
      it 'creates a pending task if assigned' do
        service.new_merge_request(mr_assigned, author)

        is_expected_to_create_pending_task(user: john_doe, target: mr_assigned, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        is_expected_to_not_create_task { service.new_merge_request(mr_unassigned, author) }
      end

      it 'does not create a task if assignee is the current user' do
        is_expected_to_not_create_task { service.new_merge_request(mr_unassigned, john_doe) }
      end
    end

    describe '#close_merge_request' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: mr_assigned, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: mr_assigned, author: author)
      end

      it 'marks related pending tasks to the target for the user as done' do
        service.close_merge_request(mr_assigned, john_doe)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end
    end

    describe '#reassigned_merge_request' do
      it 'creates a pending task for new assignee' do
        mr_unassigned.update_attribute(:assignee, john_doe)
        service.reassigned_merge_request(mr_unassigned, author)

        is_expected_to_create_pending_task(user: john_doe, target: mr_unassigned, action: Task::ASSIGNED)
      end

      it 'does not create a task if unassigned' do
        mr_assigned.update_attribute(:assignee, nil)

        is_expected_to_not_create_task { service.reassigned_merge_request(mr_assigned, author) }
      end
    end

    describe '#merge_merge_request' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: mr_assigned, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: mr_assigned, author: author)
      end

      it 'marks related pending tasks to the target for the user as done' do
        service.merge_merge_request(mr_assigned, john_doe)

        expect(first_pending_task.reload).to be_done
        expect(second_pending_task.reload).to be_done
      end
    end
  end

  def is_expected_to_create_pending_task(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Task.where(attributes).count).to eq 1
  end

  def is_expected_to_not_create_task
    expect { yield }.not_to change(Task, :count)
  end
end
