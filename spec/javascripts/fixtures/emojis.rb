require 'spec_helper'

describe 'Emojis (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('emojis/')
  end

  it 'emojis/emojis.json' do |example|
    JavaScriptFixturesHelpers::FIXTURE_PATHS.each do |fixture_path|
      next unless File.directory?(fixture_path)

      # Copying the emojis.json from the public folder
      fixture_file_name = File.expand_path('emojis/emojis.json', fixture_path)
      FileUtils.mkdir_p(File.dirname(fixture_file_name))
      FileUtils.cp(Rails.root.join('public/-/emojis/1/emojis.json'), fixture_file_name)
    end
  end
end
