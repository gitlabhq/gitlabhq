# frozen_string_literal: true

RSpec.shared_examples 'subscribes to event' do
  include AfterNextHelpers

  it 'consumes the published event', :sidekiq_inline do
    expect_next(described_class)
      .to receive(:handle_event)
      .with(instance_of(event.class))
      .and_call_original

    ::Gitlab::EventStore.publish(event)
  end

  it_behaves_like 'an idempotent worker'
end

def consume_event(subscriber:, event:)
  subscriber.new.perform(event.class.name, event.data)
end
