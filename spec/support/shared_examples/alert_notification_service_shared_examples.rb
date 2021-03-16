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

RSpec.shared_examples 'creates status-change system note for an auto-resolved alert' do
  it 'has 2 new system notes' do
    expect { subject }.to change(Note, :count).by(2)
    expect(Note.last.note).to include('Resolved')
  end
end

# Requires `source` to be defined
RSpec.shared_examples 'creates single system note based on the source of the alert' do
  it 'has one new system note' do
    expect { subject }.to change(Note, :count).by(1)
    expect(Note.last.note).to include(source)
  end
end
