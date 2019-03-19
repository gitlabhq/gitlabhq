require 'spec_helper'

describe ApplicationController, '(Static JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  Dir.glob('{,ee/}spec/javascripts/fixtures/**/*.haml').map do |file_path|
    it "static/#{file_path.sub(%r{\A(ee/)?spec/javascripts/fixtures/}, '').sub(/\.haml\z/, '.raw')}" do |example|
      store_frontend_fixture(render_template(file_path), example.description)
    end
  end

  private

  def render_template(template_file_name)
    controller = ApplicationController.new
    controller.prepend_view_path(File.dirname(template_file_name))
    controller.render_to_string(template: File.basename(template_file_name), layout: false)
  end
end
