require 'spec_helper'

describe Dashboard::ProjectsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, namespace: namespace, path: 'builds-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('dashboard/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'dashboard/user-callout.html.raw' do |example|
    rendered = render_template('shared/_user_callout')
    store_frontend_fixture(rendered, example.description)
  end

  private

  def render_template(template_file_name)
    controller.prepend_view_path(JavaScriptFixturesHelpers::FIXTURE_PATH)
    controller.render_to_string(template_file_name, layout: false)
  end
end
