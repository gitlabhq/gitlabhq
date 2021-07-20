# frozen_string_literal: true

# This shared_example requires the following variables:
# - `service`, the service which includes AlertManagement::AlertProcessing
RSpec.shared_examples 'creates an alert management alert or errors' do
  it { is_expected.to be_success }

  it 'creates AlertManagement::Alert' do
    expect(Gitlab::AppLogger).not_to receive(:warn)

    expect { subject }.to change(AlertManagement::Alert, :count).by(1)
  end

  it 'executes the alert service hooks' do
    expect_next_instance_of(AlertManagement::Alert) do |alert|
      expect(alert).to receive(:execute_integrations)
    end

    subject
  end

  context 'and fails to save' do
    let(:errors) { double(messages: { hosts: ['hosts array is over 255 chars'] })}

    before do
      allow(service).to receive(:alert).and_call_original
      allow(service).to receive_message_chain(:alert, :save).and_return(false)
      allow(service).to receive_message_chain(:alert, :errors).and_return(errors)
    end

    it_behaves_like 'alerts service responds with an error', :bad_request

    it 'writes a warning to the log' do
      expect(Gitlab::AppLogger).to receive(:warn).with(
        message: "Unable to create AlertManagement::Alert from #{source}",
        project_id: project.id,
        alert_errors: { hosts: ['hosts array is over 255 chars'] }
      )

      subject
    end
  end
end

# This shared_example requires the following variables:
# - last_alert_attributes, last created alert
# - project, project that alert created
# - payload_raw, hash representation of payload
# - environment, project's environment
# - fingerprint, fingerprint hash
RSpec.shared_examples 'properly assigns the alert properties' do
  specify do
    subject

    expect(last_alert_attributes).to match({
      project_id: project.id,
      title: payload_raw.fetch(:title),
      started_at: Time.zone.parse(payload_raw.fetch(:start_time)),
      severity: payload_raw.fetch(:severity, nil),
      status: AlertManagement::Alert.status_value(:triggered),
      events: 1,
      domain: domain,
      hosts: payload_raw.fetch(:hosts, nil),
      payload: payload_raw.with_indifferent_access,
      issue_id: nil,
      description: payload_raw.fetch(:description, nil),
      monitoring_tool: payload_raw.fetch(:monitoring_tool, nil),
      service: payload_raw.fetch(:service, nil),
      fingerprint: Digest::SHA1.hexdigest(fingerprint),
      environment_id: environment.id,
      ended_at: nil,
      prometheus_alert_id: nil
    }.with_indifferent_access)
  end
end

RSpec.shared_examples 'does not create an alert management alert' do
  specify do
    expect { subject }.not_to change(AlertManagement::Alert, :count)
  end
end

# This shared_example requires the following variables:
# - `alert`, the alert for which events should be incremented
RSpec.shared_examples 'adds an alert management alert event' do
  specify do
    expect(alert).not_to receive(:execute_integrations)

    expect { subject }.to change { alert.reload.events }.by(1)

    expect(subject).to be_success
  end

  it_behaves_like 'does not create an alert management alert'
end

# This shared_example requires the following variables:
# - `alert`, the alert for which events should not be incremented
RSpec.shared_examples 'does not add an alert management alert event' do
  specify do
    expect { subject }.not_to change { alert.reload.events }
  end
end

RSpec.shared_examples 'processes new firing alert' do
  include_examples 'processes never-before-seen alert'

  context 'for an existing alert with the same fingerprint' do
    let_it_be(:gitlab_fingerprint) { Digest::SHA1.hexdigest(fingerprint) }

    context 'which is triggered' do
      let_it_be(:alert) { create(:alert_management_alert, :triggered, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'adds an alert management alert event'
      it_behaves_like 'sends alert notification emails if enabled'
      it_behaves_like 'processes incident issues if enabled', with_issue: true

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not create a system note for alert'

      context 'with an existing resolved alert as well' do
        let_it_be(:resolved_alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: gitlab_fingerprint) }

        it_behaves_like 'adds an alert management alert event'
        it_behaves_like 'sends alert notification emails if enabled'
        it_behaves_like 'processes incident issues if enabled', with_issue: true

        it_behaves_like 'does not create an alert management alert'
        it_behaves_like 'does not create a system note for alert'
      end
    end

    context 'which is acknowledged' do
      let_it_be(:alert) { create(:alert_management_alert, :acknowledged, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'adds an alert management alert event'
      it_behaves_like 'processes incident issues if enabled', with_issue: true

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not create a system note for alert'
      it_behaves_like 'does not send alert notification emails'
    end

    context 'which is ignored' do
      let_it_be(:alert) { create(:alert_management_alert, :ignored, fingerprint: gitlab_fingerprint, project: project) }

      it_behaves_like 'adds an alert management alert event'
      it_behaves_like 'processes incident issues if enabled', with_issue: true

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not create a system note for alert'
      it_behaves_like 'does not send alert notification emails'
    end

    context 'which is resolved' do
      let_it_be(:alert) { create(:alert_management_alert, :resolved, fingerprint: gitlab_fingerprint, project: project) }

      include_examples 'processes never-before-seen alert'
    end
  end
end
