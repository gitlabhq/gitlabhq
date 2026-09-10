# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::DashboardController, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner, organization: organization) }
  let_it_be(:regular_user) { create(:user) }

  # Use without_current_organization metadata to ensure current organization isn't stubbed.
  # This enables testing Current.organization resolution from path params.
  describe 'GET /o/:organization_path/admin', :without_current_organization do
    subject(:request) { get organization_admin_root_path(organization) }

    let(:other_organization_request) { get organization_admin_root_path(other_organization) }

    it_behaves_like 'an organization admin area request'

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the organization admin dashboard content' do
        request

        expect(response.body).to include(_('Organization Administration'))
      end
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the organization admin dashboard content' do
        request

        expect(response.body).to include(_('Organization Administration'))
      end

      context 'when X-GitLab-Organization-ID header is provided' do
        it 'uses organization from path, not header' do
          header_organization = create(:organization)

          get organization_admin_root_path(organization),
            headers: { 'X-GitLab-Organization-ID' => header_organization.id.to_s }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
