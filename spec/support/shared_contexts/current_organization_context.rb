# frozen_string_literal: true

# goal of this context: provide an easy process for setting and using the current organization that is set
# in the middleware for non-feature spec level specs.
RSpec.shared_context 'with current_organization setting' do
  unless method_defined?(:current_organization)
    let_it_be(:current_organization, reload: true) { create(:organization, name: 'Current Organization') }
  end

  before do
    stub_current_organization(current_organization)
  end

  # Specs can run in a different thread/process. In these cases we stub Current.organization to match
  # our stub above to align expectations. This is especially useful for URL helpers that are Organization
  # context aware.
  #
  # rubocop:disable RSpec/UselessDynamicDefinition -- Type must be defined singularly
  [:controller, :request, :feature, :system].each do |spec_type|
    before(:each, :with_current_organization, type: spec_type) do
      allow(Current).to receive_messages(
        organization_assigned: true,
        organization: current_organization
      )
    end
  end
  # rubocop:enable RSpec/UselessDynamicDefinition
end

RSpec.configure do |rspec|
  rspec.include_context 'with current_organization setting', with_current_organization: true
end
