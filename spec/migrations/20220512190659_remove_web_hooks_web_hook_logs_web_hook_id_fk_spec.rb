# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveWebHooksWebHookLogsWebHookIdFk, feature_category: :integrations do
  let(:web_hooks) { table(:web_hooks) }
  let(:logs) { table(:web_hook_logs) }

  let!(:hook) { web_hooks.create! }

  let!(:log_a) { logs.create!(web_hook_id: hook.id, response_body: 'msg-a') }
  let!(:log_b) { logs.create!(web_hook_id: hook.id, response_body: 'msg-b') }

  describe '#up' do
    it 'allows us to delete web-hooks and leave web-hook logs intact' do
      migrate!

      expect { hook.delete }.not_to change(logs, :count)

      expect(logs.pluck(:response_body)).to match_array %w[msg-a msg-b]
    end
  end

  describe '#down' do
    it 'ensures referential integrity of hook logs' do
      migrate!
      schema_migrate_down!

      expect { hook.delete }.to change(logs, :count).by(-2)
    end
  end
end
