require 'spec_helper'

describe Gitlab::Middleware::ReadonlyGeo, lib: true do
  include Rack::Test::Methods

  RSpec::Matchers.define :be_a_redirect do
    match do |response|
      response.status == 301
    end
  end

  RSpec::Matchers.define :disallow_request do
    match do |middleware|
      flash = middleware.send(:rack_flash)
      flash['alert'] && flash['alert'].include?('You cannot do writing operations')
    end
  end

  RSpec::Matchers.define :disallow_request_in_json do
    match do |response|
      json_response = JSON.parse(response.body)
      response.body.include?('You cannot do writing operations') && json_response.key?('message')
    end
  end

  let(:rack_stack) do
    rack = Rack::Builder.new do
      use ActionDispatch::Session::CacheStore
      use ActionDispatch::Flash
      use ActionDispatch::ParamsParser
    end

    rack.run(subject)
    rack.to_app
  end

  subject { described_class.new(fake_app) }
  let(:request) { @request ||= Rack::MockRequest.new(rack_stack) }

  context 'normal requests to a secondary Gitlab Geo' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
    before(:each) { allow(Gitlab::Geo).to receive(:secondary?) { true } }

    it 'expects PATCH requests to be disallowed' do
      response = request.patch('/test_request')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    it 'expects PUT requests to be disallowed' do
      response = request.put('/test_request')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST requests to be disallowed' do
      response = request.post('/test_request')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    context 'whitelisted requests' do
      it 'expects DELETE request to logout to be allowed' do
        response = request.delete('/users/sign_out')

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request
      end
    end
  end

  context 'json requests to a secondary Geo node' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'application/json' }, ['OK']] } }
    let(:content_json) { { 'CONTENT_TYPE' => 'application/json' } }
    before(:each) { allow(Gitlab::Geo).to receive(:secondary?) { true } }

    it 'expects PATCH requests to be disallowed' do
      response = request.patch('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects PUT requests to be disallowed' do
      response = request.put('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects POST requests to be disallowed' do
      response = request.post('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request', content_json)

      expect(response).to disallow_request_in_json
    end
  end
end
