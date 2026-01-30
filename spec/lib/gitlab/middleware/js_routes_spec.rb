# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::JsRoutes, feature_category: :tooling do
  subject(:middleware) { described_class.new(app).call(env) }

  let(:app) { double('app') } # rubocop:disable RSpec/VerifiedDoubles -- stubbed app
  let(:env) do
    {
      'REQUEST_METHOD' => 'GET',
      'HTTP_ACCEPT' => 'text/html'
    }
  end

  let(:response) { [200, {}, ['OK']] }
  let(:digest_file_path) { described_class::DIGEST_FILE_PATH }
  let(:route) { double('route', verb: 'GET', path: double(spec: '/test')) } # rubocop:disable RSpec/VerifiedDoubles -- ActionDispatch::Journey::Route is a complicated class to stub. This is an isolated test that only cares about `verb` and `path` so it makes sense to use a simple double

  before do
    allow(app).to receive(:call).and_return(response)
    allow(Rails.application.routes).to receive(:routes).and_return([route])
    allow(Gitlab::JsRoutes).to receive(:generate!).and_return('')
  end

  after do
    # Clean up the digest file
    FileUtils.rm_f(digest_file_path)
  end

  shared_examples 'path helpers are regenerated' do
    it 'regenerates path helpers' do
      expect(Gitlab::JsRoutes).to receive(:generate!)
      middleware
    end
  end

  shared_examples 'path helpers are not regenerated' do
    it 'does not regenerate path helpers' do
      expect(Gitlab::JsRoutes).not_to receive(:generate!)
      middleware
    end
  end

  describe '#call' do
    it 'calls the app and returns the response' do
      expect(app).to receive(:call).with(env)
      expect(middleware).to eq(response)
    end

    it 'writes the current route digest to file' do
      digest = Digest::SHA256.hexdigest("GET /test")
      middleware
      expect(File.read(digest_file_path)).to eq(digest)
    end

    context 'when routes have changed since last call' do
      before do
        # Simulate existing digest from previous routes
        File.write(digest_file_path, 'old_digest')
      end

      context 'with GET request to HTML page' do
        it_behaves_like 'path helpers are regenerated'
      end

      context 'with GET request for JSON' do
        let(:env) { { 'REQUEST_METHOD' => 'GET', 'HTTP_ACCEPT' => 'application/json' } }

        it_behaves_like 'path helpers are not regenerated'
      end

      context 'with non-GET request' do
        let(:env) { { 'REQUEST_METHOD' => 'POST', 'HTTP_ACCEPT' => 'text/html' } }

        it_behaves_like 'path helpers are not regenerated'
      end

      context 'when HTTP_ACCEPT is nil' do
        let(:env) { { 'REQUEST_METHOD' => 'GET', 'HTTP_ACCEPT' => nil } }

        it_behaves_like 'path helpers are not regenerated'
      end
    end

    context 'when routes have not changed since last call' do
      let(:current_digest) { Digest::SHA256.hexdigest("GET /test") }

      before do
        # Simulate the digest file contains the same digest as current routes
        File.write(digest_file_path, current_digest)
      end

      it_behaves_like 'path helpers are not regenerated'
    end

    context 'when digest file does not exist' do
      it_behaves_like 'path helpers are regenerated'
    end
  end
end
