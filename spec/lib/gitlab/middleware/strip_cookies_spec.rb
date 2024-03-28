# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::StripCookies, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax
  include Rack::Test::Methods

  let(:mock_app) do
    Class.new do
      def call(env)
        [
          200,
          env,
          ['OK']
        ]
      end
    end
  end

  let(:app) { mock_app.new }

  subject do
    described_class.new(app, paths: [%r{^/assets/}])
  end

  describe '#call' do
    let(:request) { Rack::MockRequest.new(subject) }
    let(:cookie_value) { 'session=12345678;' }

    def do_request(path)
      request.get(path, { 'Set-Cookie' => cookie_value })
    end

    where(:path, :cookies_present) do
      "/assets/test.css" | false
      "/something/assets/test.css" | true
      "/merge_requests/1" | true
    end

    with_them do
      it 'returns expected cookie value' do
        response = do_request(path)

        if cookies_present
          expect(response['Set-Cookie']).to eq(cookie_value)
        else
          expect(response['Set-Cookie']).to be_nil
        end
      end
    end
  end
end
