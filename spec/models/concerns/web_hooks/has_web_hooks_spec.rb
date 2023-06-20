# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::HasWebHooks, feature_category: :webhooks do
  let(:minimal_test_class) do
    Class.new do
      include WebHooks::HasWebHooks

      def id
        1
      end
    end
  end

  before do
    stub_const('MinimalTestClass', minimal_test_class)
  end

  describe '#last_failure_redis_key' do
    subject { MinimalTestClass.new.last_failure_redis_key }

    it { is_expected.to eq('web_hooks:last_failure:minimal_test_class-1') }
  end

  describe 'last_webhook_failure', :clean_gitlab_redis_shared_state do
    subject { MinimalTestClass.new.last_webhook_failure }

    it { is_expected.to eq(nil) }

    context 'when there was an older failure', :clean_gitlab_redis_shared_state do
      let(:last_failure_date) { 1.month.ago.iso8601 }

      before do
        Gitlab::Redis::SharedState.with { |r| r.set('web_hooks:last_failure:minimal_test_class-1', last_failure_date) }
      end

      it { is_expected.to eq(last_failure_date) }
    end
  end
end
