# frozen_string_literal: true

# goal of this context: provide an easy process for setting and using the current organization that is set
# in the middleware for non-feature spec level specs.
RSpec.shared_context 'with current_organization setting' do
  include_context 'with Organization URL helpers'

  unless method_defined?(:current_organization)
    let_it_be_with_reload(:current_organization) { create(:common_organization) }
  end

  before do |example|
    next if example.metadata[:without_current_organization]

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
        rack_env = (last_request_headers.presence || {}).transform_keys do |key|
          ActionDispatch::Http::Headers.new(nil).send(:env_name, key)
        end

        context = {
          user: try(:warden)&.user,
          params: last_request_params,
          rack_env: rack_env
        }

        current_organization = Gitlab::Current::Organization.new(**context).organization
      end

      current_organization
    end
  end
end

# Feature specs drive the app through Capybara, so URL helpers evaluated in the example thread are
# not inside a request and therefore produce unscoped paths. To keep the application's paths aligned
# with them, treat the current organization as unscoped. `scoped_paths?` is the single source of
# truth that feeds both the server-side organization-aware URL helpers (Routing::OrganizationsHelper)
# and the frontend (gon.current_organization.has_scoped_paths), so forcing it to false makes paths
# unscoped everywhere. Specs that specifically exercise organization-scoped paths can stub it back.
RSpec.shared_context 'with unscoped Organization paths for feature specs' do
  before do
    # rubocop:disable RSpec/AnyInstanceOf -- scoped_paths? is evaluated on Organization records that
    # are loaded afresh while the app serves a request (in the Capybara server thread), so there is
    # no single instance to target.
    allow_any_instance_of(Organizations::Organization).to receive(:scoped_paths?).and_return(false)
    # rubocop:enable RSpec/AnyInstanceOf
  end
end

RSpec.configure do |rspec|
  # Automatically include organization context for all controller specs.
  # This ensures Current.organization is always set, preventing issues where
  # controllers or services rely on organization context.
  rspec.include_context 'with current_organization setting', type: :controller
  rspec.include_context 'with current_organization setting', type: :graphql

  # Auto-tag GraphQL request specs for organization context inclusion
  rspec.define_derived_metadata(type: :request) do |metadata|
    metadata[:with_current_organization] = true if metadata[:file_path]&.include?('spec/requests/api/graphql/')
  end

  # Allow explicit opt-in for non-controller specs using :with_current_organization tag
  rspec.include_context 'with current_organization setting', with_current_organization: true
  rspec.include_context 'with Organization URL helpers', with_organization_url_helpers: true
  rspec.include_context 'with unscoped Organization paths for feature specs', type: :feature
end

def seed_internal_bot(bot_type)
  before do
    Users::Internal.in_organization(current_organization).public_send(bot_type)
  end
end
