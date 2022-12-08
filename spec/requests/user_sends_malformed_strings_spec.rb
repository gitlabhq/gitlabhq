# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sends malformed strings', feature_category: :user_management do
  include GitHttpHelpers

  let(:null_byte) { "\u0000" }
  let(:invalid_string) { "mal\xC0formed" }

  it 'raises a 400 error with a null byte' do
    post '/nonexistent', params: { a: "A #{null_byte} nasty string" }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'raises a 400 error with an invalid string' do
    post '/nonexistent', params: { a: "A #{invalid_string} nasty string" }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'raises a 400 error with null bytes in the auth headers' do
    clone_get("project/path", user: "hello#{null_byte}", password: "nothing to see")

    expect(response).to have_gitlab_http_status(:bad_request)
  end
end
