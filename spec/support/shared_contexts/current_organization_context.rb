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

RSpec.shared_context 'with Organization URL helpers' do
  before do
    allow(Routing::OrganizationsHelper::MappedHelpers).to receive(:current_organization)
      .and_return(current_organization)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'with current_organization setting', with_current_organization: true
  rspec.include_context 'with Organization URL helpers', with_organization_url_helpers: true
end
