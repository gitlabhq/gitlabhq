# frozen_string_literal: true

# This shared_example requires the following variables:
# - issue (required)
RSpec.shared_examples 'calls the escalation status CreateService' do
  it 'calls IncidentManagement::Incidents::CreateEscalationStatusService' do
    expect_next(::IncidentManagement::IssuableEscalationStatuses::CreateService, a_kind_of(Issue))
      .to receive(:execute)

    issue
  end
end

# This shared_example requires the following variables:
# - issue (required)
RSpec.shared_examples 'does not call the escalation status CreateService' do
  it 'does not call the ::IncidentManagement::IssuableEscalationStatuses::CreateService' do
    expect(::IncidentManagement::IssuableEscalationStatuses::CreateService).not_to receive(:new)

    issue
  end
end
