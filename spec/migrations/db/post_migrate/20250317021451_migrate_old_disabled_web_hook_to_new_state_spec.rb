# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateOldDisabledWebHookToNewState, :freeze_time, feature_category: :webhooks, migration_version: 20250206114301 do
  let!(:web_hooks) { table(:web_hooks) }

  let!(:non_disabled_webhook) { web_hooks.create!(recent_failures: 3, backoff_count: 1) }
  let!(:legacy_permanently_disabled_webhook) { web_hooks.create!(recent_failures: 4, backoff_count: 1) }
  let!(:temporarily_disabled_webhook) do
    web_hooks.create!(recent_failures: 4, backoff_count: 1, disabled_until: Time.current + 1.hour)
  end

  describe '#up' do
    it 'migrates legacy permanently disabled web hooks to new permanently disabled state' do
      migrate!

      [non_disabled_webhook, temporarily_disabled_webhook, legacy_permanently_disabled_webhook].each(&:reload)

      expect(non_disabled_webhook.recent_failures).to eq(3)
      expect(non_disabled_webhook.backoff_count).to eq(1)
      expect(non_disabled_webhook.disabled_until).to be_nil

      expect(temporarily_disabled_webhook.recent_failures).to eq(4)
      expect(temporarily_disabled_webhook.backoff_count).to eq(1)
      expect(temporarily_disabled_webhook.disabled_until).to eq(Time.current + 1.hour)

      expect(legacy_permanently_disabled_webhook.recent_failures).to eq(40)
      expect(legacy_permanently_disabled_webhook.backoff_count).to eq(37)
      expect(legacy_permanently_disabled_webhook.disabled_until).to eq(Time.current)

      expect(web_hooks.where(disabled_until: nil).where('recent_failures > 3').count).to eq(0)

      expect(ProjectHook.executable.pluck_primary_key).to contain_exactly(non_disabled_webhook.id)
      expect(ProjectHook.disabled.pluck_primary_key).to contain_exactly(
        temporarily_disabled_webhook.id,
        legacy_permanently_disabled_webhook.id
      )
    end

    it 'migrates in batches' do
      web_hooks.create!(recent_failures: 4, backoff_count: 1)
      web_hooks.create!(recent_failures: 4, backoff_count: 1)

      stub_const("#{described_class}::BATCH_SIZE", 2)
      disabled_until = Time.zone.now.to_fs(:db)

      expect do
        migrate!
      end.to make_queries_matching(
        /UPDATE "web_hooks" SET "recent_failures" = 40, "backoff_count" = 37, "disabled_until" = '#{disabled_until}'/,
        2
      )
    end
  end
end
