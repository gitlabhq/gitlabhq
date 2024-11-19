# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :stub_settings_source) do |example|
    original_instance = ::Settings.instance_variable_get(:@instance)

    example.run

    ::Settings.instance_variable_set(:@instance, original_instance)
  end
end
