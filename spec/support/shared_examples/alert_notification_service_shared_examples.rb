# frozen_string_literal: true

RSpec.shared_examples 'Alert Notification Service sends notification email' do
  let(:notification_service) { spy }

  it 'sends a notification for firing alerts only' do
    expect(NotificationService)
      .to receive(:new)
      .and_return(notification_service)

    expect(notification_service)
      .to receive_message_chain(:async, :prometheus_alerts_fired)

    expect(subject).to be_success
  end
end

RSpec.shared_examples 'Alert Notification Service sends no notifications' do |http_status:|
  let(:notification_service) { spy }
  let(:create_events_service) { spy }

  it 'does not notify' do
    expect(notification_service).not_to receive(:async)
    expect(create_events_service).not_to receive(:execute)

    expect(subject).to be_error
    expect(subject.http_status).to eq(http_status)
  end
end
