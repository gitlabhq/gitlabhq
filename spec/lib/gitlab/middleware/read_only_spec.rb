# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Middleware::ReadOnly do
  include Rack::Test::Methods
  using RSpec::Parameterized::TableSyntax

  let(:rack_stack) do
    rack = Rack::Builder.new do
      use ActionDispatch::Session::CacheStore
      use ActionDispatch::Flash
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

  context 'normal requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    it 'expects PATCH requests to be disallowed' do
      response = request.patch('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects PUT requests to be disallowed' do
      response = request.put('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST requests to be disallowed' do
      response = request.post('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects a internal POST request to be allowed after a disallowed request' do
      response = request.post('/test_request')

      expect(response).to be_redirect

      response = request.post("/api/#{API::API.version}/internal")

      expect(response).not_to be_redirect
    end

    it 'expects DELETE requests to be disallowed' do
      response = request.delete('/test_request')

      expect(response).to be_redirect
      expect(subject).to disallow_request
    end

    it 'expects POST of new file that looks like an LFS batch url to be disallowed' do
      expect(Rails.application.routes).to receive(:recognize_path).and_call_original
      response = request.post('/root/gitlab-ce/new/master/app/info/lfs/objects/batch')

      expect(response).to be_redirect
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

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      context 'sidekiq admin requests' do
        where(:mounted_at) do
          [
            '',
            '/',
            '/gitlab',
            '/gitlab/',
            '/gitlab/gitlab',
            '/gitlab/gitlab/'
          ]
        end

        with_them do
          before do
            stub_config_setting(relative_url_root: mounted_at)
          end

          it 'allows requests' do
            path = File.join(mounted_at, 'admin/sidekiq')
            response = request.post(path)

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request

            response = request.get(path)

            expect(response).not_to be_redirect
            expect(subject).not_to disallow_request
          end
        end
      end

      where(:description, :path) do
        'LFS request to batch'        | '/root/rouge.git/info/lfs/objects/batch'
        'LFS request to locks verify' | '/root/rouge.git/info/lfs/locks/verify'
        'LFS request to locks create' | '/root/rouge.git/info/lfs/locks'
        'LFS request to locks unlock' | '/root/rouge.git/info/lfs/locks/1/unlock'
        'request to git-upload-pack'  | '/root/rouge.git/git-upload-pack'
        'request to git-receive-pack' | '/root/rouge.git/git-receive-pack'
      end

      with_them do
        it "expects a POST #{description} URL to be allowed" do
          expect(Rails.application.routes).to receive(:recognize_path).and_call_original
          response = request.post(path)

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end
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
