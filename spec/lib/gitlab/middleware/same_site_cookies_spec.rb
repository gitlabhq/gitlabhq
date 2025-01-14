# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SameSiteCookies do
  using RSpec::Parameterized::TableSyntax
  include Rack::Test::Methods

  let(:user_agent) { nil }
  let(:mock_app) do
    Class.new do
      attr_reader :cookies, :user_agent

      def initialize(cookies)
        @cookies = cookies
      end

      def call(env)
        [
          200,
          { 'Set-Cookie' => cookies },
          ['OK']
        ]
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
      request.post('/some/path', { 'HTTP_USER_AGENT' => user_agent }.compact)
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
        let(:cookies) { "" }

        it 'does not add headers' do
          response = do_request

          expect(response['Set-Cookie']).to eq("")
        end
      end

      context 'with different browsers' do
        where(:description, :user_agent, :expected) do
          "iOS 12" | "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1" | false
          "macOS 10.14 + Safari" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" | false
          "macOS 10.14 + Opera" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.78 Safari/537.36 OPR/47.0.2631.55" | false
          "macOS 10.14 + Chrome v80" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" | true
          "Chrome v41" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36" | true
          "Chrome v50" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2348.1 Safari/537.36" | true
          "Chrome v51" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2718.15 Safari/537.36" | false
          "Chrome v62" | "Mozilla/5.0 (Macintosh; Intel NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36" | false
          "Chrome v66" | "Mozilla/5.0 (Linux; Android 4.4.2; Avvio_793 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.126 Mobile Safari/537.36" | false
          "Chrome v67" | "Mozilla/5.0 (Linux; Android 7.1.1; SM-J510F Build/NMF26X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3371.0 Mobile Safari/537.36" | true
          "Chrome v85" | "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36" | true
          "Chromium v66" | "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/66.0.3359.181 HeadlessChrome/66.0.3359.181 Safari/537.36" | false
          "Chromium v85" | "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/85.0.4183.59 Chrome/85.0.4183.59 Safari/537.36" | true
          "UC Browser 12.0.4" | "Mozilla/5.0 (Linux; U; Android 4.4.4; zh-CN; A31 Build/KTU84P) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/12.0.4.986 Mobile Safari/537.36" | false
          "UC Browser 12.13.0" | "Mozilla/5.0 (Linux; U; Android 7.1.1; en-US; SM-C9000 Build/NMF26X) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/12.13.0.1207 Mobile Safari/537.36" | false
          "UC Browser 12.13.2" | "Mozilla/5.0 (Linux; U; Android 9; en-US; Redmi Note 7 Build/PQ3B.190801.002) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/12.13.2.1208 Mobile Safari/537.36" | true
          "UC Browser 12.13.5" | "Mozilla/5.0 (Linux; U; Android 5.1.1; en-US; PHICOMM C630 (CLUE L) Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.108 UCBrowser/12.13.5.1209 Mobile Safari/537.36" | true
          "Playstation" | "Mozilla/5.0 (PlayStation 4 2.51) AppleWebKit/537.73 (KHTML, like Gecko)" | true
        end

        with_them do
          let(:cookies) { "thiscookie=12345" }

          it 'returns expected SameSite status' do
            response = do_request

            if expected
              expect(response['Set-Cookie']).to include('SameSite=None')
            else
              expect(response['Set-Cookie']).not_to include('SameSite=None')
            end
          end
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
