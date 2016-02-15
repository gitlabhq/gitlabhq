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
