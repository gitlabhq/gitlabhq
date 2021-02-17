# frozen_string_literal: true

RSpec.shared_examples 'Alert Notification Service sends notification email' do
  let(:notification_service) { spy }

  it 'sends a notification' do
    expect(NotificationService)
      .to receive(:new)
      .and_return(notification_service)

    expect(notification_service)
      .to receive_message_chain(:async, :prometheus_alerts_fired)

    expect(subject).to be_success
  end
end

RSpec.shared_examples 'Alert Notification Service sends no notifications' do |http_status: nil|
  it 'does not notify' do
    expect(NotificationService).not_to receive(:new)

    if http_status.present?
      expect(subject).to be_error
      expect(subject.http_status).to eq(http_status)
    else
      expect(subject).to be_success
    end
  end
end
