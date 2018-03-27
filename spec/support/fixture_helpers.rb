module FixtureHelpers
  def fixture_file(filename, dir: '')
    return '' if filename.blank?

    File.read(expand_fixture_path(filename, dir: dir))
  end

  def expand_fixture_path(filename, dir: '')
    File.expand_path(Rails.root.join(dir, 'spec', 'fixtures', filename))
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
