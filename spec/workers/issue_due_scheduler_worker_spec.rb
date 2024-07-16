# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueDueSchedulerWorker, feature_category: :team_planning do
  describe '#perform' do
    it 'schedules one MailScheduler::IssueDueWorker per project with open issues due tomorrow' do
      project1 = create(:project)
      project2 = create(:project)
      project_closed_issue = create(:project)
      project_issue_due_another_day = create(:project)

      create(:issue, :opened, project: project1, due_date: Date.tomorrow)
      create(:issue, :opened, project: project1, due_date: Date.tomorrow)
      create(:issue, :opened, project: project2, due_date: Date.tomorrow)
      create(:issue, :closed, project: project_closed_issue, due_date: Date.tomorrow)
      create(:issue, :opened, project: project_issue_due_another_day, due_date: Date.today)

      expect(MailScheduler::IssueDueWorker).to receive(:bulk_perform_async) do |args|
        expect(args).to match_array([[project1.id], [project2.id]])
      end

      described_class.new.perform
    end

    it 'does not schedule MailScheduler::IssueDueWorker for issues that have the work_item_type different of "issue"' do
      project1 = create(:project)
      project2 = create(:project)

      # rubocop: disable Cop/AvoidBecomes -- The lookup still done by issues,
      # so for now we need to ensure the Issue type
      create(:work_item, :issue, :opened, project: project1, due_date: Date.tomorrow).becomes(Issue)
      create(:work_item, :epic, :opened, project: project2, due_date: Date.tomorrow).becomes(Issue)
      # rubocop: enable Cop/AvoidBecomes

      expect(MailScheduler::IssueDueWorker).to receive(:bulk_perform_async) do |args|
        expect(args).to match_array([[project1.id]])
      end

      described_class.new.perform
    end
  end
end
