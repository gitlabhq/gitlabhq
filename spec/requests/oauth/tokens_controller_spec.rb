# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController do
  it 'allows cross-origin POST requests' do
    post '/oauth/token', headers: { 'Origin' => 'http://notgitlab.com' }

    expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
    expect(response.headers['Access-Control-Allow-Methods']).to eq 'POST'
    expect(response.headers['Access-Control-Allow-Headers']).to be_nil
    expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
  end
end
