# frozen_string_literal: true

RSpec.shared_context 'with default_organization setting', shared_context: :metadata do # rubocop:disable RSpec/SharedGroupsMetadata -- We are actually using this for easy metadata setting
  let_it_be(:default_organization) { create(:organization, :default) }
end

RSpec.configure do |rspec|
  rspec.include_context 'with default_organization setting', with_default_organization: true
end
