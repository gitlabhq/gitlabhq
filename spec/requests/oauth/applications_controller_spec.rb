# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ApplicationsController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, owner: user) }
  let(:show_path) { oauth_application_path(application) }
  let(:create_path) { oauth_applications_path }

  before do
    sign_in(user)
  end

  include_examples 'applications controller - GET #show'

  include_examples 'applications controller - POST #create'

  context 'on GET #index' do
    def perform_scopes_action
      get oauth_applications_path
    end

    include_examples 'applications controller - scopes include mcp'
  end

  describe 'organization maintenance mode enforcement' do
    let_it_be_with_reload(:organization) { create(:organization) }
    let_it_be(:user) { create(:user, organization: organization) }

    subject(:request) { get oauth_applications_path }

    it_behaves_like 'a controller request enforcing organization maintenance mode'
  end
end
