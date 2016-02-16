require 'spec_helper'

describe TaskService, services: true do
  let(:service) { described_class.new }

  describe 'Issues' do
    let(:author) { create(:user) }
    let(:john_doe) { create(:user) }
    let(:project) { create(:empty_project, :public) }
    let(:assigned_issue) { create(:issue, project: project, assignee: john_doe) }
    let(:unassigned_issue) { create(:issue, project: project, assignee: nil) }

    before do
      project.team << [author, :developer]
      project.team << [john_doe, :developer]
    end

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

        expect(first_pending_task.reload.done?).to eq true
        expect(second_pending_task.reload.done?).to eq true
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

    describe '#mark_as_done' do
      let!(:first_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      let!(:second_pending_task) do
        create(:pending_assigned_task, user: john_doe, project: project, target: assigned_issue, author: author)
      end

      it 'marks related pending tasks to the target for the user as done' do
        service.mark_as_done(assigned_issue, john_doe)

        expect(first_pending_task.reload.done?).to eq true
        expect(second_pending_task.reload.done?).to eq true
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
