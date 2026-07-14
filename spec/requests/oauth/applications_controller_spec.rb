# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ApplicationsController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, owner: user) }
  let_it_be(:show_path) { oauth_application_path(application) }
  let_it_be(:create_path) { oauth_applications_path }

  before do
    sign_in(user)
  end

  include_examples 'applications controller - GET #show'

  include_examples 'applications controller - GET #new'

  include_examples 'applications controller - POST #create'
end
