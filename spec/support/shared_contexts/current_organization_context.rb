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
end

RSpec.configure do |rspec|
  rspec.include_context 'with current_organization setting', with_current_organization: true
end
