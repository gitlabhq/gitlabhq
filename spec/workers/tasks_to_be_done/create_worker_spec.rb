# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TasksToBeDone::CreateWorker, feature_category: :onboarding do
  let_it_be(:member_task) { create(:member_task, tasks: MemberTask::TASKS.values) }
  let_it_be(:current_user) { create(:user) }

  let(:assignee_ids) { [1, 2] }
  let(:job_args) { [member_task.id, current_user.id, assignee_ids] }

  before do
    member_task.project.group.add_owner(current_user)
  end

  describe '.perform' do
    it 'executes the task services for all tasks to be done', :aggregate_failures do
      MemberTask::TASKS.each_key do |task|
        service_class = "TasksToBeDone::Create#{task.to_s.camelize}TaskService".constantize

        expect(service_class)
          .to receive(:new)
          .with(container: member_task.project, current_user: current_user, assignee_ids: assignee_ids)
          .and_call_original
      end

      expect { described_class.new.perform(*job_args) }.to change { Issue.count }.by(3)
    end
  end

  include_examples 'an idempotent worker' do
    it 'creates 3 task issues' do
      expect { subject }.to change { Issue.count }.by(3)
    end
  end
end
