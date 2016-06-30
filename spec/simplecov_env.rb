require 'simplecov'

SimpleCov.configure do
  load_profile :rails

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

  add_group 'Services', 'app/services'
  add_group 'Finders', 'app/finders'
  add_group 'Uploaders', 'app/uploaders'
  add_group 'Validators', 'app/validators'

  merge_timeout 7200
end
