# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailScheduler::IssueDueWorker, feature_category: :team_planning do
  describe '#perform' do
    let(:worker) { described_class.new }
    let(:project) { create(:project) }

    it 'sends emails for open issues due tomorrow in the project specified' do
      issue1 = create(:issue, :opened, project: project, due_date: Date.tomorrow)
      issue2 = create(:issue, :opened, project: project, due_date: Date.tomorrow)
      create(:issue, :closed, project: project, due_date: Date.tomorrow) # closed
      create(:issue, :opened, project: project, due_date: 2.days.from_now) # due on another day
      create(:issue, :opened, due_date: Date.tomorrow) # different project

      expect(worker.notification_service).to receive(:issue_due).with(issue1)
      expect(worker.notification_service).to receive(:issue_due).with(issue2)

      worker.perform(project.id)
    end

    it 'does not send email for issues that have the work_item_type different of "issue"' do
      # rubocop: disable Cop/AvoidBecomes -- The lookup still done by issues,
      # so for now we need to ensure the Issue type
      issue = create(:work_item, :issue, :opened, project: project, due_date: Date.tomorrow).becomes(Issue)
      epic = create(:work_item, :epic, :opened, project: project, due_date: Date.tomorrow).becomes(Issue)
      # rubocop: enable Cop/AvoidBecomes

      expect(worker.notification_service).to receive(:issue_due).with(issue)
      expect(worker.notification_service).not_to receive(:issue_due).with(epic)

      worker.perform(project.id)
    end
  end
end
