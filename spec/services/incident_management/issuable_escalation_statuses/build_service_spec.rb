# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::BuildService do
  let_it_be(:project) { create(:project) }
  let_it_be(:incident, reload: true) { create(:incident, project: project) }

  let(:service) { described_class.new(incident) }

  subject(:execute) { service.execute }

  it_behaves_like 'initializes new escalation status with expected attributes'

  context 'with associated alert' do
    let_it_be(:alert) { create(:alert_management_alert, :acknowledged, project: project, issue: incident) }

    it_behaves_like 'initializes new escalation status with expected attributes', { status_event: :acknowledge }
  end
end
