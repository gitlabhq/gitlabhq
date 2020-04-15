# frozen_string_literal: true

RSpec.shared_examples 'returning response status' do |status|
  it "returns #{status}" do
    subject

    expect(response).to have_gitlab_http_status(status)
  end
end
