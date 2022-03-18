# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::ActionCableRedisListener do
  let(:adapter) { instance_double('ActionCable::SubscriptionAdapter::Redis') }
  let(:connection) { instance_double('Redis') }
  let(:listener) { ActionCable::SubscriptionAdapter::Redis::Listener.new(adapter, nil) }

  before do
    allow(Thread).to receive(:new).and_yield
    allow(adapter).to receive(:redis_connection_for_subscriptions).and_return(connection)
  end

  it 'catches Redis connection errors and restarts Action Cable' do
    expect(connection).to receive(:without_reconnect).and_raise Redis::ConnectionError
    expect(ActionCable).to receive_message_chain(:server, :restart)

    expect { listener.add_channel('test_channel', nil) }.not_to raise_error
  end

  it 're-raises other exceptions' do
    expect(connection).to receive(:without_reconnect).and_raise StandardError
    expect(ActionCable).not_to receive(:server)

    expect { listener.add_channel('test_channel', nil) }.to raise_error(StandardError)
  end
end
