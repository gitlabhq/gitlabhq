# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PruneWebHookLogsWorker do
  describe '#perform' do
    before do
      hook = create(:project_hook)

      create(:web_hook_log, web_hook: hook, created_at: 5.months.ago)
      create(:web_hook_log, web_hook: hook, created_at: 4.months.ago)
      create(:web_hook_log, web_hook: hook, created_at: 91.days.ago)
      create(:web_hook_log, web_hook: hook, created_at: 89.days.ago)
      create(:web_hook_log, web_hook: hook, created_at: 2.months.ago)
      create(:web_hook_log, web_hook: hook, created_at: 1.month.ago)
      create(:web_hook_log, web_hook: hook, response_status: '404')
    end

    it 'removes all web hook logs older than 90 days' do
      described_class.new.perform

      expect(WebHookLog.count).to eq(4)
      expect(WebHookLog.last.response_status).to eq('404')
    end
  end
end
