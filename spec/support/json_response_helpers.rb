shared_context 'JSON response' do
  let(:json_response) { JSON.parse(response.body) }
end

RSpec.configure do |config|
  config.include_context 'JSON response'
  config.include_context 'JSON response', type: :request
  config.include_context 'JSON response', :api
end
