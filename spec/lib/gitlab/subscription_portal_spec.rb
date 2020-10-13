# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::SubscriptionPortal do
  describe '.default_subscriptions_url' do
    subject { described_class.default_subscriptions_url }

    context 'on non test and non dev environments' do
      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      end

      it 'returns production subscriptions app URL' do
        is_expected.to eq('https://customers.gitlab.com')
      end
    end

    context 'on dev environment' do
      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(true)
      end

      it 'returns staging subscriptions app url' do
        is_expected.to eq('https://customers.stg.gitlab.com')
      end
    end

    context 'on test environment' do
      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(true)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      end

      it 'returns staging subscriptions app url' do
        is_expected.to eq('https://customers.stg.gitlab.com')
      end
    end
  end
end
