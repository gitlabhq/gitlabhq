# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::LinkAlerts::DestroyService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:another_incident) { create(:incident, project: project) }
  let_it_be(:internal_alert) { create(:alert_management_alert, project: project, issue: incident) }
  let_it_be(:external_alert) { create(:alert_management_alert, project: another_project, issue: incident) }
  let_it_be(:unrelated_alert) { create(:alert_management_alert, project: project, issue: another_incident) }

  describe '#execute' do
    subject(:execute) { described_class.new(incident, current_user, alert).execute }

    let(:alert) { internal_alert }

    context 'when current user is a guest' do
      let(:current_user) { guest }

      it 'responds with error', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.message).to eq('You have insufficient permissions to manage alerts for this project')
      end

      it 'does not unlink alert from the incident' do
        expect { execute }.not_to change { incident.reload.alert_management_alerts.to_a }
      end
    end

    context 'when current user is a developer' do
      let(:current_user) { developer }

      it 'responds with success', :aggregate_failures do
        response = execute

        expect(response).to be_success
        expect(response.payload[:incident]).to eq(incident)
      end

      context 'when unlinking internal alert' do
        let(:alert) { internal_alert }

        it 'unlinks the alert' do
          expect { execute }
            .to change { incident.reload.alert_management_alerts.to_a }
            .to match_array([external_alert])
        end
      end

      context 'when unlinking external alert' do
        let(:alert) { external_alert }

        it 'unlinks the alert' do
          expect { execute }
            .to change { incident.reload.alert_management_alerts.to_a }
            .to match_array([internal_alert])
        end
      end

      context 'when unlinking an alert not related to the incident' do
        let(:alert) { unrelated_alert }

        it "does not change the incident's alerts" do
          expect { execute }.not_to change { incident.reload.alert_management_alerts.to_a }
        end

        it "does not change another incident's alerts" do
          expect { execute }.not_to change { another_incident.reload.alert_management_alerts.to_a }
        end

        it "does not change the alert's incident" do
          expect { execute }.not_to change { unrelated_alert.reload.issue }
        end
      end
    end
  end
end
