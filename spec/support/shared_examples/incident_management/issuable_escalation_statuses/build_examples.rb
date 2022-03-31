# frozen_string_literal: true

RSpec.shared_examples 'initializes new escalation status with expected attributes' do |attributes = {}|
  let(:expected_attributes) { attributes }

  specify do
    expect { execute }.to change { incident.escalation_status }
      .from(nil)
      .to(instance_of(::IncidentManagement::IssuableEscalationStatus))

    expect(incident.escalation_status).to have_attributes(
      id: nil,
      issue_id: incident.id,
      policy_id: nil,
      escalations_started_at: nil,
      status_event: nil,
      **expected_attributes
    )
  end
end
