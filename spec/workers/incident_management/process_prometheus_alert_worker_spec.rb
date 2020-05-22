# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::ProcessPrometheusAlertWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:prometheus_alert) { create(:prometheus_alert, project: project) }
    let(:payload_key) { Gitlab::Alerting::Alert.new(project: project, payload: alert_params).gitlab_fingerprint }
    let!(:prometheus_alert_event) { create(:prometheus_alert_event, prometheus_alert: prometheus_alert, payload_key: payload_key) }

    let(:alert_params) do
      {
        startsAt: prometheus_alert.created_at.rfc3339,
        labels: {
          gitlab_alert_id: prometheus_alert.prometheus_metric_id
        }
      }.with_indifferent_access
    end

    it 'creates an issue' do
      expect { subject.perform(project.id, alert_params) }
        .to change(Issue, :count)
        .by(1)
    end

    it 'relates issue to an event' do
      expect { subject.perform(project.id, alert_params) }
        .to change(prometheus_alert.related_issues, :count)
        .from(0)
        .to(1)
    end

    context 'resolved event' do
      let(:issue) { create(:issue, project: project) }

      before do
        prometheus_alert_event.related_issues << issue
        prometheus_alert_event.resolve
      end

      it 'does not create an issue' do
        expect { subject.perform(project.id, alert_params) }
          .not_to change(Issue, :count)
      end

      it 'closes the existing issue' do
        expect { subject.perform(project.id, alert_params) }
          .to change { issue.reload.state }
          .from('opened')
          .to('closed')
      end

      it 'leaves a system note on the issue' do
        expect(SystemNoteService)
          .to receive(:auto_resolve_prometheus_alert)

        subject.perform(project.id, alert_params)
      end
    end

    context 'when project could not be found' do
      let(:non_existing_project_id) { non_existing_record_id }

      it 'does not create an issue' do
        expect { subject.perform(non_existing_project_id, alert_params) }
          .not_to change(Issue, :count)
      end

      it 'does not relate issue to an event' do
        expect { subject.perform(non_existing_project_id, alert_params) }
          .not_to change(prometheus_alert.related_issues, :count)
      end
    end

    context 'when event could not be found' do
      before do
        alert_params[:labels][:gitlab_alert_id] = non_existing_record_id
      end

      it 'does not create an issue' do
        expect { subject.perform(project.id, alert_params) }
          .not_to change(Issue, :count)
      end

      it 'does not relate issue to an event' do
        expect { subject.perform(project.id, alert_params) }
          .not_to change(prometheus_alert.related_issues, :count)
      end
    end

    context 'when issue could not be created' do
      before do
        allow_next_instance_of(IncidentManagement::CreateIssueService) do |instance|
          allow(instance).to receive(:execute).and_return( { error: true } )
        end
      end

      it 'does not relate issue to an event' do
        expect { subject.perform(project.id, alert_params) }
          .not_to change(prometheus_alert.related_issues, :count)
      end
    end

    context 'self-managed alert' do
      let(:alert_name) { 'alert' }
      let(:starts_at) { Time.now.rfc3339 }

      let!(:prometheus_alert_event) do
        create(:self_managed_prometheus_alert_event, project: project, payload_key: payload_key)
      end

      let(:alert_params) do
        {
          startsAt: starts_at,
          generatorURL: 'http://localhost:9090/graph?g0.expr=vector%281%29&g0.tab=1',
          labels: {
            alertname: alert_name
          }
        }.with_indifferent_access
      end

      it 'creates an issue' do
        expect { subject.perform(project.id, alert_params) }
          .to change(Issue, :count)
          .by(1)
      end

      it 'relates issue to an event' do
        expect { subject.perform(project.id, alert_params) }
          .to change(prometheus_alert_event.related_issues, :count)
          .from(0)
          .to(1)
      end

      context 'when event could not be found' do
        before do
          alert_params[:generatorURL] = 'http://somethingelse.com'
        end

        it 'creates an issue' do
          expect { subject.perform(project.id, alert_params) }
            .to change(Issue, :count)
            .by(1)
        end

        it 'does not relate issue to an event' do
          expect { subject.perform(project.id, alert_params) }
            .not_to change(prometheus_alert.related_issues, :count)
        end
      end
    end
  end
end
