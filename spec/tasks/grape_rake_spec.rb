# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'grape rake tasks', :silence_stdout, feature_category: :api do
  before do
    Rake.application.rake_require 'tasks/grape'
  end

  describe 'grape:routes' do
    subject(:run_task) { run_rake_task('grape:routes') }

    it 'prints one line per API route, prefixed with its HTTP method', :aggregate_failures do
      run_task

      route_lines = $stdout.string.lines.grep(%r{\A(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|\*) /api/})

      expect(route_lines.count).to eq(API::API.routes.count)
      expect($stdout.string).to match(%r{^GET /api/:version/version\(\.:format\) - })
      # Regression check: a line starting with a space means the HTTP method
      # resolved to nil (the Grape 2.4 upgrade stopped merging `method` into
      # `route.options`, so it must be read from `route.request_method`).
      expect($stdout.string).not_to match(%r{^ /api/})
    end
  end
end
