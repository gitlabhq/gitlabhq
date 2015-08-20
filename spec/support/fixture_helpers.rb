module FixtureHelpers
  def fixture_file(filename)
    return '' if filename.blank?
    file_path = File.expand_path(Rails.root.join('spec/fixtures/', filename))
    File.read(file_path)
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
