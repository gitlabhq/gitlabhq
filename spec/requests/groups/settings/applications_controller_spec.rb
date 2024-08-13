# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::ApplicationsController, feature_category: :system_access do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:application) { create(:oauth_application, owner_id: group.id, owner_type: 'Namespace') }
  let_it_be(:show_path) { group_settings_application_path(group, application) }
  let_it_be(:create_path) { group_settings_applications_path(group) }

  before do
    sign_in(user)
    group.add_owner(user)
  end

  include_examples 'applications controller - GET #show'

  include_examples 'applications controller - GET #new'

  include_examples 'applications controller - POST #create'
end
