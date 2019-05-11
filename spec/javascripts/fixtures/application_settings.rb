require 'spec_helper'

describe Admin::ApplicationSettingsController, '(JavaScript fixtures)', type: :controller do
  include StubENV
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'application-settings') }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('application_settings/')
  end

  after do
    remove_repository(project)
  end

  it 'application_settings/accounts_and_limit.html' do
    stub_application_setting(user_default_external: false)

    get :show

    expect(response).to be_success
  end
end
