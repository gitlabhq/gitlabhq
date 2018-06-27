RSpec.configure do |config|
  config.include_context 'JSON response'
  config.include_context 'JSON response', type: :request
  config.include_context 'JSON response', :api
end
