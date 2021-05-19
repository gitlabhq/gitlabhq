# frozen_string_literal: true

# This shared_example requires the following variables:
# - `alert`, the alert to be resolved
RSpec.shared_examples 'resolves an existing alert management alert' do
  it 'sets the end time and status' do
    expect(Gitlab::AppLogger).not_to receive(:warn)

    expect { subject }
      .to change { alert.reload.resolved? }.to(true)
      .and change { alert.ended_at.present? }.to(true)

    expect(subject).to be_success
  end
end

# This shared_example requires the following variables:
# - `alert`, the alert not to be updated
RSpec.shared_examples 'does not change the alert end time' do
  specify do
    expect { subject }.not_to change { alert.reload.ended_at }
  end
end

# This shared_example requires the following variables:
# - `project`, expected project for an incoming alert
# - `service`, a service which includes AlertManagement::AlertProcessing
# - `alert` (optional), the alert which should fail to resolve. If not
#             included, the log is expected to correspond to a new alert
RSpec.shared_examples 'writes a warning to the log for a failed alert status update' do
  before do
    allow(service).to receive(:alert).and_call_original
    allow(service).to receive_message_chain(:alert, :resolve).and_return(false)
  end

  specify do
    expect(Gitlab::AppLogger).to receive(:warn).with(
      message: 'Unable to update AlertManagement::Alert status to resolved',
      project_id: project.id,
      alert_id: alert ? alert.id : (last_alert_id + 1)
    )

    # Failure to resolve a recovery alert is not a critical failure
    expect(subject).to be_success
  end

  private

  def last_alert_id
    AlertManagement::Alert.connection
      .select_value("SELECT nextval('#{AlertManagement::Alert.sequence_name}')")
  end
end

RSpec.shared_examples 'processes recovery alert' do
  context 'seen for the first time' do
    let(:alert) { AlertManagement::Alert.last }

    include_examples 'processes never-before-seen recovery alert'
  end

  context 'for an existing alert with the same fingerprint' do
    let_it_be(:gitlab_fingerprint) { Digest::SHA1.hexdigest(fingerprint) }

    context 'which is triggered' do
      let_it_be(:alert) { create(:alert_management_alert, :triggered, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      it_behaves_like 'resolves an existing alert management alert'
      it_behaves_like 'creates expected system notes for alert', :recovery_alert, :resolve_alert
      it_behaves_like 'sends alert notification emails if enabled'
      it_behaves_like 'closes related incident if enabled'
      it_behaves_like 'writes a warning to the log for a failed alert status update'

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not process incident issues'
      it_behaves_like 'does not add an alert management alert event'
    end

    context 'which is ignored' do
      let_it_be(:alert) { create(:alert_management_alert, :ignored, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      it_behaves_like 'resolves an existing alert management alert'
      it_behaves_like 'creates expected system notes for alert', :recovery_alert, :resolve_alert
      it_behaves_like 'sends alert notification emails if enabled'
      it_behaves_like 'closes related incident if enabled'
      it_behaves_like 'writes a warning to the log for a failed alert status update'

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not process incident issues'
      it_behaves_like 'does not add an alert management alert event'
    end

    context 'which is acknowledged' do
      let_it_be(:alert) { create(:alert_management_alert, :acknowledged, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      it_behaves_like 'resolves an existing alert management alert'
      it_behaves_like 'creates expected system notes for alert', :recovery_alert, :resolve_alert
      it_behaves_like 'sends alert notification emails if enabled'
      it_behaves_like 'closes related incident if enabled'
      it_behaves_like 'writes a warning to the log for a failed alert status update'

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not process incident issues'
      it_behaves_like 'does not add an alert management alert event'
    end

    context 'which is resolved' do
      let_it_be(:alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      include_examples 'processes never-before-seen recovery alert'
    end
  end
end
