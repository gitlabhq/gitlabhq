require 'simplecov'

SimpleCov.configure do
  load_profile 'test_frameworks'
  track_files '{app,lib}/**/*.rb'

  if ENV['CI_BUILD_NAME']
    coverage_dir "coverage/#{ENV['CI_BUILD_NAME']}"
    command_name ENV['CI_BUILD_NAME']
  end

  if ENV['CI']
    SimpleCov.at_exit do
      # In CI environment don't generate formatted reports
      # Only generate .resultset.json
      SimpleCov.result
    end
  end

  add_filter '/vendor/ruby/'
  add_filter 'config/initializers/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Mailers', 'app/mailers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Workers', %w(app/jobs app/workers)
  add_group 'Libraries', 'lib'
  add_group 'Services', 'app/services'
  add_group 'Finders', 'app/finders'
  add_group 'Uploaders', 'app/uploaders'
  add_group 'Validators', 'app/validators'

  merge_timeout 7200
end
