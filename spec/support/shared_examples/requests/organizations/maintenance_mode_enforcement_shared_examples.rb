# frozen_string_literal: true

# Shared example for API requests that enforce organization maintenance mode.
#
# Requires the caller to define:
# - `organization`: the request's organization, able to enter maintenance mode
#   (must not already be in maintenance; the example transitions it)
# - `request`: makes the request under test
# - `success_status`: the HTTP status returned when maintenance is not enforced
RSpec.shared_examples 'an API request enforcing organization maintenance mode' do
  context 'for a time-bounded maintenance reason' do
    before do
      organization.start_maintenance(maintenance_reason: 'migration')
      organization.confirm_maintenance
    end

    it 'blocks the request with service unavailable and a Retry-After header', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:service_unavailable)
      expect(json_response['message'])
        .to eq(_('This organization is temporarily unavailable due to maintenance.'))
      expect(response.headers['Retry-After']).to eq('60')
    end
  end

  context 'for an indefinite maintenance reason' do
    before do
      organization.start_maintenance(maintenance_reason: 'legal')
      organization.confirm_maintenance
    end

    it 'blocks the request with forbidden and no Retry-After header', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['message']).to include(_('This organization is unavailable.'))
      expect(response.headers['Retry-After']).to be_nil
    end
  end

  context 'when enforcement is disabled' do
    before do
      organization.start_maintenance(maintenance_reason: 'migration')
      organization.confirm_maintenance
      stub_feature_flags(organization_maintenance_enforcement: false)
    end

    it 'allows the request' do
      request

      expect(response).to have_gitlab_http_status(success_status)
    end
  end
end
