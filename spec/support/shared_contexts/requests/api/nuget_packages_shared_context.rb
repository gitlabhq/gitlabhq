# frozen_string_literal: true

RSpec.shared_context 'nuget api setup' do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be_with_reload(:job) { create(:ci_build, user: user, status: :running, project: project) }
end
