# frozen_string_literal: true

RSpec.shared_examples 'returning response status with message' do |status:, message: nil|
  it "returns #{status} and message: #{message}" do
    subject

    expect(response).to have_gitlab_http_status(status)
    expect(json_response['message']).to eq(message)
  end
end
