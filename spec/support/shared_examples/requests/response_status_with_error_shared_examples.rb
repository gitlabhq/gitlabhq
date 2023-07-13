# frozen_string_literal: true

RSpec.shared_examples 'returning response status with error' do |status:, error: nil|
  it "returns #{status} and error message" do
    subject

    expect(response).to have_gitlab_http_status(status)
    expect(json_response['error']).to be_present
    expect(json_response['error']).to match(error) if error
  end
end
