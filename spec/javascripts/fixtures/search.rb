require 'spec_helper'

describe SearchController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  render_views

  before(:all) do
    clean_frontend_fixtures('search/')
  end

  it 'search/show.html.raw' do |example|
    get :show

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
