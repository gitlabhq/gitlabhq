# frozen_string_literal: true

return unless ENV['CI']
return unless ENV['GENERATE_FRONTEND_FIXTURES_MAPPING'] == 'true'

RSpec.configure do |config|
  config.before(:suite) do
    $fixtures_mapping = Hash.new { |h, k| h[k] = [] } # rubocop:disable Style/GlobalVars
  end

  config.after(:suite) do
    next unless ENV['FRONTEND_FIXTURES_MAPPING_PATH']

    File.write(ENV['FRONTEND_FIXTURES_MAPPING_PATH'], $fixtures_mapping.to_json) # rubocop:disable Style/GlobalVars
  end
end
