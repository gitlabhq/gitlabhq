# frozen_string_literal: true
class BaseGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path("../../tmp", File.dirname(__FILE__))
  setup :prepare_destination
end
