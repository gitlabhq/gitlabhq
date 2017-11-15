module FixtureHelpers
  def fixture_file(filename)
    return '' if filename.blank?

    File.read(expand_fixture_path(filename))
  end

  def expand_fixture_path(filename)
    File.expand_path(Rails.root.join('spec/fixtures/', filename))
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
