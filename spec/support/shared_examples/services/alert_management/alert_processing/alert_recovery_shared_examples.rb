# frozen_string_literal: true

# This shared_example requires the following variables:
# - `alert`, the alert to be resolved
RSpec.shared_examples 'resolves an existing alert management alert' do
  it 'sets the end time and status' do
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

RSpec.shared_examples 'processes recovery alert' do
  context 'seen for the first time' do
    let(:alert) { AlertManagement::Alert.last }

    it_behaves_like 'alerts service responds with an error and takes no actions', :bad_request
  end

  context 'for an existing alert with the same fingerprint' do
    let_it_be(:gitlab_fingerprint) { Digest::SHA1.hexdigest(fingerprint) }

    context 'which is triggered' do
      let_it_be(:alert) { create(:alert_management_alert, :triggered, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      it_behaves_like 'resolves an existing alert management alert'
      it_behaves_like 'creates expected system notes for alert', :recovery_alert, :resolve_alert
      it_behaves_like 'sends alert notification emails if enabled'
      it_behaves_like 'closes related incident if enabled'

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

      it_behaves_like 'does not create an alert management alert'
      it_behaves_like 'does not process incident issues'
      it_behaves_like 'does not add an alert management alert event'
    end

    context 'which is resolved' do
      let_it_be(:alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: gitlab_fingerprint, monitoring_tool: source) }

      it_behaves_like 'alerts service responds with an error and takes no actions', :bad_request
    end
  end
end
