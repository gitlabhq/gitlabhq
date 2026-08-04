# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::ApplicationsController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }
  let_it_be(:application) { create(:oauth_application, owner_id: group.id, owner_type: 'Namespace') }
  let(:show_path) { group_settings_application_path(group, application) }
  let(:create_path) { group_settings_applications_path(group) }

  before do
    sign_in(user)
  end

  include_examples 'applications controller - GET #show'

  include_examples 'applications controller - POST #create'

  context 'on GET #index' do
    def perform_scopes_action
      get group_settings_applications_path(group)
    end

    include_examples 'applications controller - scopes include mcp'
  end

  context 'on GET #edit' do
    def perform_scopes_action
      get edit_group_settings_application_path(group, application)
    end

    include_examples 'applications controller - scopes include mcp'
  end
end
