require 'spec_helper'

context 'U2F' do
  include JavaScriptFixturesHelpers

  let(:user) { create(:user, :two_factor_via_u2f) }

  before(:all) do
    clean_frontend_fixtures('u2f/')
  end

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
    end

    it 'u2f/authenticate.html.raw' do |example|
      allow(controller).to receive(:find_user).and_return(user)

      post :create, user: { login: user.username, password: user.password }

      expect(response).to be_success
      store_frontend_fixture(response, example.description)
    end
  end

  describe Profiles::TwoFactorAuthsController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
    end

    it 'u2f/register.html.raw' do |example|
      get :show

      expect(response).to be_success
      store_frontend_fixture(response, example.description)
    end
  end
end
