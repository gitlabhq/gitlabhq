require 'spec_helper'

describe IssueDueWorker do
  describe 'perform' do
    let(:worker) { described_class.new }

    it 'finds issues due on the day run' do
      issue1 = create(:issue, :opened, due_date: Date.today)
      issue3 = create(:issue, :opened, due_date: 3.days.from_now)
      issue4 = create(:issue, :opened, due_date: 4.days.from_now)

      expect_any_instance_of(NotificationService).to receive(:issue_due_email).with(issue1)

      worker.perform
    end
  end
end
