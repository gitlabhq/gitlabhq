# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SameSiteCookies do
  include Rack::Test::Methods

  let(:mock_app) do
    Class.new do
      attr_reader :cookies

      def initialize(cookies)
        @cookies = cookies
      end

      def call(env)
        [200, { 'Set-Cookie' => cookies }, ['OK']]
      end
    end
  end

  let(:app) { mock_app.new(cookies) }

  subject do
    described_class.new(app)
  end

  describe '#call' do
    let(:request) { Rack::MockRequest.new(subject) }

    def do_request
      request.post('/some/path')
    end

    context 'without SSL enabled' do
      before do
        allow(Gitlab.config.gitlab).to receive(:https).and_return(false)
      end

      context 'with cookie' do
        let(:cookies) { "thiscookie=12345" }

        it 'does not add headers to cookies' do
          response = do_request

          expect(response['Set-Cookie']).to eq(cookies)
        end
      end
    end

    context 'with SSL enabled' do
      before do
        allow(Gitlab.config.gitlab).to receive(:https).and_return(true)
      end

      context 'with no cookies' do
        let(:cookies) { nil }

        it 'does not add headers' do
          response = do_request

          expect(response['Set-Cookie']).to be_nil
        end
      end

      context 'with single cookie' do
        let(:cookies) { "thiscookie=12345" }

        it 'adds required headers' do
          response = do_request

          expect(response['Set-Cookie']).to eq("#{cookies}; Secure; SameSite=None")
        end
      end

      context 'multiple cookies' do
        let(:cookies) { "thiscookie=12345\nanother_cookie=56789" }

        it 'adds required headers' do
          response = do_request

          expect(response['Set-Cookie']).to eq("thiscookie=12345; Secure; SameSite=None\nanother_cookie=56789; Secure; SameSite=None")
        end
      end

      context 'multiple cookies with some missing headers' do
        let(:cookies) { "thiscookie=12345; SameSite=None\nanother_cookie=56789; Secure" }

        it 'adds missing headers' do
          response = do_request

          expect(response['Set-Cookie']).to eq("thiscookie=12345; SameSite=None; Secure\nanother_cookie=56789; Secure; SameSite=None")
        end
      end

      context 'multiple cookies with all headers present' do
        let(:cookies) { "thiscookie=12345; Secure; SameSite=None\nanother_cookie=56789; Secure; SameSite=None" }

        it 'does not add new headers' do
          response = do_request

          expect(response['Set-Cookie']).to eq(cookies)
        end
      end
    end
  end
end
