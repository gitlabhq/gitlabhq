# frozen_string_literal: true

require 'spec_helper'

# Use without_current_organization metadata to ensure current organization isn't stubbed.
# This enables testing Current.organization resolution from path params.
RSpec.describe Admin::Organizations::SettingsController, :without_current_organization,
  feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner, organization: organization) }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET /o/:organization_path/admin/settings/general' do
    subject(:request) { get general_organization_admin_settings_path(organization) }

    let(:other_organization_request) { get general_organization_admin_settings_path(other_organization) }

    it_behaves_like 'an organization admin area request'
  end
end
