# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::LinkAlerts::CreateService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:linked_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:alert1) { create(:alert_management_alert, project: project) }
  let_it_be(:alert2) { create(:alert_management_alert, project: project) }
  let_it_be(:external_alert) { create(:alert_management_alert, project: another_project) }
  let_it_be(:incident) { create(:incident, project: project, alert_management_alerts: [linked_alert]) }
  let_it_be(:guest) { create(:user, guest_of: [project, another_project]) }
  let_it_be(:developer) { create(:user, developer_of: [project, another_project]) }
  let_it_be(:another_developer) { create(:user, developer_of: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(incident, current_user, alert_references).execute }

    let(:alert_references) { [alert1.to_reference, alert2.details_url] }

    context 'when current user is a guest' do
      let(:current_user) { guest }

      it 'responds with error', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.message).to eq('You have insufficient permissions to manage alerts for this project')
      end

      it 'does not link alerts to the incident' do
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

      it 'links alerts to the incident' do
        expect { execute }
          .to change { incident.reload.alert_management_alerts.to_a }
          .from([linked_alert])
          .to match_array([linked_alert, alert1, alert2])
      end

      context 'when linking an already linked alert' do
        let(:alert_references) { [linked_alert.details_url] }

        it 'does not change incident alerts list' do
          expect { execute }.not_to change { incident.reload.alert_management_alerts.to_a }
        end
      end

      context 'when linking an alert from another project' do
        let(:alert_references) { [external_alert.details_url] }

        it 'links an external alert to the incident' do
          expect { execute }
            .to change { incident.reload.alert_management_alerts.to_a }
            .from([linked_alert])
            .to match_array([linked_alert, external_alert])
        end
      end
    end

    context 'when current user does not have permission to read alerts on external project' do
      let(:current_user) { another_developer }

      context 'when linking alerts from current and external projects' do
        let(:alert_references) { [alert1.details_url, external_alert.details_url] }

        it 'links only alerts the current user can read' do
          expect { execute }
            .to change { incident.reload.alert_management_alerts.to_a }
            .from([linked_alert])
            .to match_array([linked_alert, alert1])
        end
      end
    end
  end
end
