# frozen_string_literal: true

RSpec.configure do |config|
  config.include_context 'JSON response', type: :controller
  config.include_context 'JSON response', type: :request
  config.include_context 'JSON response', :api
end
