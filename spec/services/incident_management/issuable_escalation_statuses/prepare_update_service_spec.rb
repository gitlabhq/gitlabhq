# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService, factory_default: :keep,
  feature_category: :incident_management do
  let_it_be(:project) { create_default(:project) }
  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, :triggered) }
  let_it_be(:user_with_permissions) { create(:user) }

  let(:current_user) { user_with_permissions }
  let(:issue) { escalation_status.issue }
  let(:status) { :acknowledged }
  let(:params) { { status: status } }
  let(:service) { described_class.new(issue, current_user, params) }

  subject(:result) { service.execute }

  before do
    issue.project.add_developer(user_with_permissions)
  end

  shared_examples 'successful response' do |payload|
    it 'returns valid parameters which can be used to update the issue' do
      expect(result).to be_success
      expect(result.payload).to eq(escalation_status: payload)
    end
  end

  shared_examples 'error response' do |message|
    specify do
      expect(result).to be_error
      expect(result.message).to eq(message)
    end
  end

  shared_examples 'availability error response' do
    include_examples 'error response', 'Escalation status updates are not available for this issue, user, or project.'
  end

  shared_examples 'invalid params error response' do
    include_examples 'error response', 'Invalid value was provided for parameters: status'
  end

  it_behaves_like 'successful response', { status_event: :acknowledge }

  context 'when user is anonymous' do
    let(:current_user) { nil }

    it_behaves_like 'availability error response'
  end

  context 'when user does not have permissions' do
    let(:current_user) { create(:user) }

    it_behaves_like 'availability error response'
  end

  context 'when called with an unsupported issue type' do
    let(:issue) { create(:issue) }

    it_behaves_like 'availability error response'
  end

  context 'when an IssuableEscalationStatus record for the issue does not exist' do
    let(:issue) { create(:incident) }

    it_behaves_like 'successful response', { status_event: :acknowledge }

    it 'initializes an issuable escalation status record' do
      expect { result }.not_to change(::IncidentManagement::IssuableEscalationStatus, :count)
      expect(issue.escalation_status).to be_present
    end
  end

  context 'when called nil params' do
    let(:params) { nil }

    it 'raises an exception' do
      expect { result }.to raise_error NoMethodError
    end
  end

  context 'when called without params' do
    let(:params) { {} }

    it_behaves_like 'successful response', {}
  end

  context 'when called with unsupported params' do
    let(:params) { { escalations_started_at: Time.current } }

    it_behaves_like 'successful response', {}
  end

  context 'with status param' do
    context 'when status matches the current status' do
      let(:params) { { status: :triggered } }

      it_behaves_like 'successful response', {}
    end

    context 'when status is unsupported' do
      let(:params) { { status: :mitigated } }

      it_behaves_like 'invalid params error response'
    end

    context 'when status is a String' do
      let(:params) { { status: 'acknowledged' } }

      it_behaves_like 'successful response', { status_event: :acknowledge }
    end
  end
end
