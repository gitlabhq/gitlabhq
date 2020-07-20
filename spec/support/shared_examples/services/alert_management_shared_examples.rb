# frozen_string_literal: true

RSpec.shared_examples 'creates an alert management alert' do
  it { is_expected.to be_success }

  it 'creates AlertManagement::Alert' do
    expect { subject }.to change(AlertManagement::Alert, :count).by(1)
  end

  it 'executes the alert service hooks' do
    slack_service = create(:service, type: 'SlackService', project: project, alert_events: true, active: true)

    subject

    expect(ProjectServiceWorker).to have_received(:perform_async).with(slack_service.id, an_instance_of(Hash))
  end
end

RSpec.shared_examples 'does not an create alert management alert' do
  it 'does not create alert' do
    expect { subject }.not_to change(AlertManagement::Alert, :count)
  end
end

RSpec.shared_examples 'adds an alert management alert event' do
  it { is_expected.to be_success }

  it 'does not create an alert' do
    expect { subject }.not_to change(AlertManagement::Alert, :count)
  end

  it 'increases alert events count' do
    expect { subject }.to change { alert.reload.events }.by(1)
  end

  it 'does not executes the alert service hooks' do
    expect(alert).not_to receive(:execute_services)

    subject
  end
end
