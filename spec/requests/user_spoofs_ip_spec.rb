# frozen_string_literal: true

require 'spec_helper'

describe 'User spoofs their IP' do
  it 'raises a 400 error' do
    get '/nonexistent', headers: { 'Client-Ip' => '1.2.3.4', 'X-Forwarded-For' => '5.6.7.8' }

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(response.body).to eq('Bad Request')
  end
end
