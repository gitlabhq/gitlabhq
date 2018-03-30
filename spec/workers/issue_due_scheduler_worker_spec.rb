require 'spec_helper'

describe IssueDueSchedulerWorker do
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

      expect(MailScheduler::IssueDueWorker).to receive(:perform_async).with(project1.id)
      expect(MailScheduler::IssueDueWorker).to receive(:perform_async).with(project2.id)

      described_class.new.perform
    end
  end
end
