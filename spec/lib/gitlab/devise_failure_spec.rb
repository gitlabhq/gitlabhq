# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DeviseFailure do
  let(:env) do
    {
      'REQUEST_URI' => 'http://test.host/',
      'HTTP_HOST' => 'test.host',
      'REQUEST_METHOD' => 'GET',
      'warden.options' => { scope: :user },
      'rack.session' => {},
      'rack.session.options' => {},
      'rack.input' => "",
      'warden' => OpenStruct.new(message: nil)
    }
  end

  let(:response) { described_class.call(env).to_a }
  let(:request) { ActionDispatch::Request.new(env) }

  context 'When redirecting' do
    it 'sets the expire_after key' do
      response

      expect(env['rack.session.options']).to have_key(:expire_after)
    end

    it 'returns to the default redirect location' do
      expect(response.first).to eq(302)
      expect(request.flash[:alert]).to eq('You need to sign in or sign up before continuing.')
      expect(response.second['Location']).to eq('http://test.host/users/sign_in')
    end
  end
end
