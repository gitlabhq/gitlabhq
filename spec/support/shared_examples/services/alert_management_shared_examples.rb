# frozen_string_literal: true

RSpec.shared_examples 'creates an alert management alert' do
  it { is_expected.to be_success }

  it 'creates AlertManagement::Alert' do
    expect { subject }.to change(AlertManagement::Alert, :count).by(1)
  end

  it 'executes the alert service hooks' do
    expect_next_instance_of(AlertManagement::Alert) do |alert|
      expect(alert).to receive(:execute_services)
    end

    subject
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

RSpec.shared_examples 'processes incident issues' do
  let(:create_incident_service) { spy }

  before do
    allow_any_instance_of(AlertManagement::Alert).to receive(:execute_services)
  end

  it 'processes issues' do
    expect(IncidentManagement::ProcessAlertWorker)
      .to receive(:perform_async)
      .with(nil, nil, kind_of(Integer))
      .once

    Sidekiq::Testing.inline! do
      expect(subject).to be_success
    end
  end
end

RSpec.shared_examples 'does not process incident issues' do
  it 'does not process issues' do
    expect(IncidentManagement::ProcessAlertWorker)
      .not_to receive(:perform_async)

    expect(subject).to be_success
  end
end

RSpec.shared_examples 'does not process incident issues due to error' do |http_status:|
  it 'does not process issues' do
    expect(IncidentManagement::ProcessAlertWorker)
      .not_to receive(:perform_async)

    expect(subject).to be_error
    expect(subject.http_status).to eq(http_status)
  end
end
