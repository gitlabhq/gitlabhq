# frozen_string_literal: true

# Expects usage of 'incident settings enabled' context.
#
# This shared_example includes the following option:
# - count: number of notifications expected to be sent
RSpec.shared_examples 'sends alert notification emails if enabled' do |count: 1|
  include_examples 'sends alert notification emails', count

  context 'with email setting disabled' do
    let(:send_email) { false }

    it_behaves_like 'does not send alert notification emails'
  end
end

RSpec.shared_examples 'sends alert notification emails' do |count: 1|
  let(:notification_async) { double(NotificationService::Async) }

  specify do
    allow(NotificationService).to receive_message_chain(:new, :async).and_return(notification_async)
    expect(notification_async).to receive(:prometheus_alerts_fired).exactly(count).times

    subject
  end
end

RSpec.shared_examples 'does not send alert notification emails' do
  specify do
    expect(NotificationService).not_to receive(:new)

    subject
  end
end
