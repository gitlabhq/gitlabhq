# frozen_string_literal: true

# Shared behaviour for the org_mover maintenance transition services
# (Organizations::{Start,Confirm,Cancel,Exit}MaintenanceService).
#
# The including spec must define:
# - `event`: the state-machine event the service drives (e.g. :confirm_maintenance)
# - `from_state` / `to_state`: the source and target state names
# - `log_message`: the message logged on a successful transition
# - `invalid_state_message`: the error when the org is not in `from_state`
# - `fallback_message`: the error when the transition fails without model errors
# - a `reach_source_state` helper that moves `organization` into `from_state`
# - an `invalid_state_setup` helper that moves `organization` into a state that
#   is neither `from_state` nor `to_state`
RSpec.shared_examples 'an org_mover maintenance transition service' do
  describe '#execute' do
    context 'when the organization is in the source state' do
      before do
        reach_source_state
      end

      it 'transitions the organization to the target state', :aggregate_failures do
        expect { response }.to change { organization.reload.state_name }.from(from_state).to(to_state)
        expect(response).to be_success
        expect(response.payload[:organization]).to eq(organization)
      end

      it 'logs the event' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          'class' => described_class.name,
          'message' => log_message,
          Labkit::Fields::GL_ORGANIZATION_ID => organization.id
        ))

        response
      end
    end

    context 'when the organization is already in the target state' do
      before do
        reach_target_state
      end

      it 'is a no-op and returns success without re-running the transition', :aggregate_failures do
        expect(organization).not_to receive(event)
        expect(response).to be_success
        expect(organization.reload.state_name).to eq(to_state)
      end
    end

    context 'when the organization is in an invalid state' do
      before do
        invalid_state_setup
      end

      it 'returns an error and does not transition', :aggregate_failures do
        expect(response).to be_error
        expect(response.message).to eq(invalid_state_message)
        expect(response.payload[:organization]).to be_nil
      end
    end

    context 'when the transition fails without adding errors' do
      before do
        reach_source_state
        allow(organization).to receive(event).and_return(false)
      end

      it 'returns the fallback error message', :aggregate_failures do
        expect(response).to be_error
        expect(response.message).to eq(fallback_message)
      end
    end
  end
end
