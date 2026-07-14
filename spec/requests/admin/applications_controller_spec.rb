# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationsController, :enable_admin_mode, feature_category: :system_access do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:application) { create(:oauth_application, owner_id: nil, owner_type: nil) }
  let_it_be(:show_path) { admin_application_path(application) }
  let_it_be(:create_path) { admin_applications_path }

  before do
    sign_in(admin)
  end

  include_examples 'applications controller - GET #show'

  include_examples 'applications controller - GET #new'

  include_examples 'applications controller - POST #create'
end
