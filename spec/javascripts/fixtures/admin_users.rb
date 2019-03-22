require 'spec_helper'

describe Admin::UsersController, '(JavaScript fixtures)', type: :controller do
  include StubENV
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('admin/users')
  end

  it 'admin/users/new_with_internal_user_regex.html.raw' do |example|
    stub_application_setting(user_default_external: true)
    stub_application_setting(user_default_internal_regex: '^(?:(?!\.ext@).)*$\r?')

    get :new

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
