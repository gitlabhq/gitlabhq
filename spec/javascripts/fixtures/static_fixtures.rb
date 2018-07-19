require 'spec_helper'

describe ApplicationController, '(Static JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('static/')
  end

  JavaScriptFixturesHelpers::FIXTURE_PATHS.each do |fixture_path|
    fixtures_path = File.expand_path(fixture_path, Rails.root)

    Dir.glob(File.expand_path('**/*.haml', fixtures_path)).map do |file_path|
      template_file_name = file_path.sub(/\A#{fixtures_path}#{File::SEPARATOR}/, '')

      it "static/#{template_file_name.sub(/\.haml\z/, '.raw')}" do |example|
        fixture_file_name = example.description
        rendered = render_template(fixture_path, template_file_name)
        store_frontend_fixture(rendered, fixture_file_name)
      end
    end
  end

  private

  def render_template(fixture_path, template_file_name)
    controller = ApplicationController.new
    controller.prepend_view_path(fixture_path)
    controller.render_to_string(template: template_file_name, layout: false)
  end
end
