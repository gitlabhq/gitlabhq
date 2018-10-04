require 'spec_helper'

describe PruneWebHookLogsWorker do
  describe '#perform' do
    before do
      hook = create(:project_hook)

      5.times do
        create(:web_hook_log, web_hook: hook, created_at: 5.months.ago)
      end

      create(:web_hook_log, web_hook: hook, response_status: '404')
    end

    it 'removes all web hook logs older than one month' do
      described_class.new.perform

      expect(WebHookLog.count).to eq(1)
      expect(WebHookLog.first.response_status).to eq('404')
    end
  end
end
