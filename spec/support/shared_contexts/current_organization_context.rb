# frozen_string_literal: true

# goal of this context: provide an easy process for setting and using the current organization that is set
# in the middleware for non-feature spec level specs.
RSpec.shared_context 'with current_organization setting' do
  include_context 'with Organization URL helpers'

  unless method_defined?(:current_organization)
    let_it_be(:current_organization, reload: true) { create(:common_organization) }
  end

  before do
    stub_current_organization(current_organization)
  end
end

# Ensure URL helpers in specs are aligned with their use in Rails.
# We do this by making sure the URL helpers use the same current Organization that Rails would use.
RSpec.shared_context 'with Organization URL helpers' do
  include_context 'with last http request'

  before do
    allow(Routing::OrganizationsHelper::MappedHelpers).to receive(:current_organization) do
      next unless Gitlab::Routing::OrganizationsHelper.organization_scoped_route?(last_request_path)

      current_organization ||= nil

      unless current_organization
        context = {
          user: try(:warden)&.user,
          params: last_request_params,
          headers: last_request_headers || {}
        }

        current_organization = Gitlab::Current::Organization.new(**context).organization
      end

      current_organization
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'with current_organization setting', with_current_organization: true
  rspec.include_context 'with Organization URL helpers', with_organization_url_helpers: true
end
