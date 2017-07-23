require 'spec_helper'

describe RemoveOldWebHookLogsWorker do
  subject { described_class.new }

  describe '#perform' do
    let!(:week_old_record) { create(:web_hook_log, created_at: Time.now - 1.week) }
    let!(:three_days_old_record) { create(:web_hook_log, created_at: Time.now - 3.days) }
    let!(:one_day_old_record) { create(:web_hook_log, created_at: Time.now - 1.day) }

    it 'removes web hook logs older than 2 days' do
      subject.perform

      expect(WebHookLog.all).to include(one_day_old_record)
      expect(WebHookLog.all).not_to include(week_old_record, three_days_old_record)
    end
  end
end
