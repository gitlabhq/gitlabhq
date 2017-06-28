require 'spec_helper'

describe ApplicationController, '(Static JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('static/')
  end

  fixtures_path = File.expand_path(JavaScriptFixturesHelpers::FIXTURE_PATH, Rails.root)
  haml_fixtures = Dir.glob(File.expand_path('**/*.haml', fixtures_path)).map do |file_path|
    file_path.sub(/\A#{fixtures_path}#{File::SEPARATOR}/, '')
  end

  haml_fixtures.each do |template_file_name|
    it "static/#{template_file_name.sub(/\.haml\z/, '.raw')}" do |example|
      fixture_file_name = example.description
      rendered = render_template(template_file_name)
      store_frontend_fixture(rendered, fixture_file_name)
    end
  end

  private

  def render_template(template_file_name)
    fixture_path = JavaScriptFixturesHelpers::FIXTURE_PATH
    controller = ApplicationController.new
    controller.prepend_view_path(fixture_path)
    controller.render_to_string(template: template_file_name, layout: false)
  end
end
