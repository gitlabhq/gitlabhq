module FixtureHelpers
  def fixture_file(filename)
    return '' if filename.blank?

    File.read(expand_fixture_path(filename))
  end

  def fixture_file_ee(filename)
    return '' if filename.blank?

    File.read(expand_fixture_ee_path(filename))
  end

  def expand_fixture_path(filename)
    File.expand_path(Rails.root.join('spec/fixtures/', filename))
  end

  def expand_fixture_ee_path(filename)
    File.expand_path(Rails.root.join('spec/ee/fixtures/', filename))
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
