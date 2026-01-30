# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:js:routes', feature_category: :tooling do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/js_routes'
  end

  before do
    allow(Gitlab::JsRoutes).to receive(:generate!).and_return('')
  end

  subject(:rake_task) { run_rake_task('gitlab:js:routes') }

  it 'calls Gitlab::JsRoutes#generate!' do
    expect(Gitlab::JsRoutes).to receive(:generate!)

    rake_task
  end
end
