# frozen_string_literal: true

RSpec.shared_examples 'applications controller - GET #show' do
  describe 'GET #show' do
    it 'renders template' do
      get show_path

      expect(response).to render_template :show
    end
  end
end

RSpec.shared_examples 'applications controller - GET #new' do
  it "sets `@scopes` to list of all scopes that should be shown" do
    create_application

    expect(assigns[:scopes]).to match_array(%w[
      admin_mode
      ai_features
      api
      create_runner
      email
      k8s_proxy
      manage_runner
      openid
      profile
      read_api
      read_observability
      read_repository
      read_service_ping
      read_user
      sudo
      write_observability
      write_repository
    ])
  end
end

RSpec.shared_examples 'applications controller - POST #create' do
  it "sets `@created` instance variable to `true`" do
    create_application

    expect(assigns[:created]).to eq(true)
  end
end

def create_application
  create_params = attributes_for(:application, trusted: true, confidential: false, scopes: ['api'])
  post create_path, params: { doorkeeper_application: create_params }
end
