# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::ProcessPrometheusAlertWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:prometheus_alert) { create(:prometheus_alert, project: project) }
    let(:payload_key) { Gitlab::AlertManagement::Payload::Prometheus.new(project: project, payload: alert_params).gitlab_fingerprint }
    let!(:prometheus_alert_event) { create(:prometheus_alert_event, prometheus_alert: prometheus_alert, payload_key: payload_key) }
    let!(:settings) { create(:project_incident_management_setting, project: project, create_issue: true) }

    let(:alert_params) do
      {
        startsAt: prometheus_alert.created_at.rfc3339,
        labels: {
          gitlab_alert_id: prometheus_alert.prometheus_metric_id
        }
      }.with_indifferent_access
    end

    it 'does nothing' do
      expect { subject.perform(project.id, alert_params) }
        .not_to change(Issue, :count)
    end
  end
end
