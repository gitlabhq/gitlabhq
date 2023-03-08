# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::CreateService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }

  let(:incident) { create(:incident, project: project) }
  let(:service) { described_class.new(incident) }

  subject(:execute) { service.execute }

  it 'creates an escalation status for the incident with no policy set' do
    expect { execute }.to change { incident.reload.escalation_status }.from(nil)

    status = incident.escalation_status

    expect(status.policy_id).to eq(nil)
    expect(status.escalations_started_at).to eq(nil)
    expect(status.status_name).to eq(:triggered)
  end

  context 'existing escalation status' do
    let!(:existing_status) { create(:incident_management_issuable_escalation_status, issue: incident) }

    it 'exits without changing anything' do
      expect { execute }.not_to change { incident.reload.escalation_status }
    end
  end
end
