# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sends null bytes as params' do
  let(:null_byte) { "\u0000" }

  it 'raises a 400 error' do
    post '/nonexistent', params: { a: "A #{null_byte} nasty string" }

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(response.body).to eq('Bad Request')
  end
end
