# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebHooks::Logger, feature_category: :webhooks do
  describe '.log_stale_access' do
    let_it_be(:hook) { create(:project_hook) }
    let_it_be(:web_hook_log) { create(:web_hook_log, web_hook: hook, created_at: 8.days.ago) }
    let_it_be(:user) { create(:user) }

    it 'logs a structured, greppable event for the stale access' do
      expect(described_class).to receive(:build).and_call_original
      expect_next_instance_of(described_class) do |logger|
        expect(logger).to receive(:info).with(
          class: described_class.name,
          event: described_class::STALE_LOG_ACCESS_EVENT,
          message: described_class::STALE_LOG_ACCESS_MESSAGE,
          hook_id: hook.id,
          web_hook_log_id: web_hook_log.id,
          web_hook_log_created_at: web_hook_log.created_at,
          action: 'show',
          interface: 'web',
          user_id: user.id,
          Labkit::Fields::GL_ORGANIZATION_ID => hook.parent&.organization_id
        )
      end

      described_class.log_stale_access(
        hook: hook, web_hook_log: web_hook_log, action: 'show', interface: 'web', user: user
      )
    end

    context 'when user is nil' do
      it 'logs a nil user_id' do
        expect_next_instance_of(described_class) do |logger|
          expect(logger).to receive(:info).with(hash_including(user_id: nil))
        end

        described_class.log_stale_access(
          hook: hook, web_hook_log: web_hook_log, action: 'retry', interface: 'api', user: nil
        )
      end
    end
  end
end
