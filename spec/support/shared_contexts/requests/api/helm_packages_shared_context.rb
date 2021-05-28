# frozen_string_literal: true

RSpec.shared_context 'helm api setup' do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
end
