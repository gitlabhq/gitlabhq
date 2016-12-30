require 'spec_helper'

describe SessionsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('u2f/')
  end

  it 'u2f/authenticate.html.raw' do |example|
    fixture = render_template('u2f/_authenticate.html.haml', locals: {
      new_user_session_path: "/users/sign_in",
      params: {},
      resource_name: "user"
    })
    store_frontend_fixture(fixture, example.description)
  end

  it 'u2f/register.html.raw' do |example|
    user = build(:user, :two_factor_via_otp)

    fixture = render_template('u2f/_register.html.haml', locals: {
      create_u2f_profile_two_factor_auth_path: '/profile/two_factor_auth/create_u2f',
      current_user: user
    })
    store_frontend_fixture(fixture, example.description)
  end

  private

  def render_template(template, **args)
    controller = ApplicationController.new
    controller.render_to_string(template: template, layout: false, **args)
  end
end
