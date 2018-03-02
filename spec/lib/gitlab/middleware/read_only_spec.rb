require 'spec_helper'

describe Gitlab::Middleware::ReadOnly do
  include Rack::Test::Methods

  RSpec::Matchers.define :be_a_redirect do
    match do |response|
      response.status == 301
    end
  end

  RSpec::Matchers.define :disallow_request do
    match do |middleware|
      alert = middleware.env['rack.session'].to_hash
        .dig('flash', 'flashes', 'alert')

      alert&.include?('You cannot perform write operations')
    end
  end

  RSpec::Matchers.define :disallow_request_in_json do
    match do |response|
      json_response = JSON.parse(response.body)
      response.body.include?('You cannot perform write operations') && json_response.key?('message')
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

  let(:observe_env) do
    Module.new do
      attr_reader :env

      def call(env)
        @env = env
        super
      end
    end
  end

  let(:request) { Rack::MockRequest.new(rack_stack) }

  subject do
    described_class.new(fake_app).tap do |app|
      app.extend(observe_env)
    end
  end

  context 'normal requests to a read-only Gitlab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

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

    it 'expects a internal POST request to be allowed after a disallowed request' do
      response = request.post('/test_request')

      expect(response).to be_a_redirect

      response = request.post("/api/#{API::API.version}/internal")

      expect(response).not_to be_a_redirect
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST of new file that looks like an LFS batch url to be disallowed' do
      expect(Rails.application.routes).to receive(:recognize_path).and_call_original
      response = request.post('/root/gitlab-ce/new/master/app/info/lfs/objects/batch')

      expect(response).to be_a_redirect
      expect(subject).to disallow_request
    end

    it 'returns last_vistited_url for disallowed request' do
      response = request.post('/test_request')

      expect(response.location).to eq 'http://localhost/'
    end

    context 'whitelisted requests' do
      it 'expects a POST internal request to be allowed' do
        expect(Rails.application.routes).not_to receive(:recognize_path)

        response = request.post("/api/#{API::API.version}/internal")

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects a POST LFS request to batch URL to be allowed' do
        expect(Rails.application.routes).to receive(:recognize_path).and_call_original
        response = request.post('/root/rouge.git/info/lfs/objects/batch')

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects a POST request to git-upload-pack URL to be allowed' do
        expect(Rails.application.routes).to receive(:recognize_path).and_call_original
        response = request.post('/root/rouge.git/git-upload-pack')

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request
      end

      it 'expects requests to sidekiq admin to be allowed' do
        response = request.post('/admin/sidekiq')

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request

        response = request.get('/admin/sidekiq')

        expect(response).not_to be_a_redirect
        expect(subject).not_to disallow_request
      end
    end
  end

  context 'json requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'application/json' }, ['OK']] } }
    let(:content_json) { { 'CONTENT_TYPE' => 'application/json' } }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

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
