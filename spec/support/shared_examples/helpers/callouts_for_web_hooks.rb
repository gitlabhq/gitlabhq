# frozen_string_literal: true

RSpec.shared_examples 'CalloutsHelper#web_hook_disabled_dismissed shared examples' do
  context 'when the web-hook failure callout has never been dismissed' do
    it 'is false' do
      expect(helper).not_to be_web_hook_disabled_dismissed(container)
    end
  end

  context 'when the web-hook failure callout has been dismissed', :freeze_time, :clean_gitlab_redis_shared_state do
    before do
      create(factory,
        feature_name: Users::CalloutsHelper::WEB_HOOK_DISABLED,
        user: user,
        dismissed_at: 1.week.ago,
        container_key => container)
    end

    it 'is true' do
      expect(helper).to be_web_hook_disabled_dismissed(container)
    end

    it 'is true when passed as a presenter' do
      skip "Does not apply to #{container.class}" unless container.is_a?(Presentable)

      expect(helper).to be_web_hook_disabled_dismissed(container.present)
    end

    context 'when there was an older failure' do
      before do
        Gitlab::Redis::SharedState.with { |r| r.set(key, 1.month.ago.iso8601) }
      end

      it 'is true' do
        expect(helper).to be_web_hook_disabled_dismissed(container)
      end
    end

    context 'when there has been a more recent failure' do
      before do
        Gitlab::Redis::SharedState.with { |r| r.set(key, 1.day.ago.iso8601) }
      end

      it 'is false' do
        expect(helper).not_to be_web_hook_disabled_dismissed(container)
      end
    end
  end
end
