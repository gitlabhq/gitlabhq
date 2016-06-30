if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start :rails do
    if ENV['CI_BUILD_NAME']
      coverage_dir "coverage/#{ENV['CI_BUILD_NAME']}"
      command_name ENV['CI_BUILD_NAME']
      merge_timeout 7200
    end

    add_filter '/vendor/ruby/'

    add_group 'Services', 'app/services'
    add_group 'Finders', 'app/finders'
    add_group 'Uploaders', 'app/uploaders'
    add_group 'Validators', 'app/validators'
  end
end
