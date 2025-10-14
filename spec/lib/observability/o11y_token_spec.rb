# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::O11yToken, feature_category: :observability do
  let(:o11y_settings) do
    instance_double(
      Observability::GroupO11ySetting,
      o11y_service_url: 'https://o11y.example.com',
      o11y_service_user_email: 'test@example.com',
      o11y_service_password: 'password123',
      created_at: 1.hour.ago
    )
  end

  let(:success_response) do
    {
      'data' => {
        'userId' => '123',
        'accessJwt' => 'access_token_123',
        'refreshJwt' => 'refresh_token_456'
      }
    }
  end

  let(:http_response) do
    instance_double(
      HTTParty::Response,
      code: 200,
      body: Gitlab::Json.dump(success_response)
    )
  end

  describe '#new_settings?' do
    subject(:o11y_token) { described_class.new(o11y_settings) }

    context 'when settings are created within the buffer time' do
      let(:o11y_settings) do
        instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: 'https://o11y.example.com',
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 2.minutes.ago
        )
      end

      it 'returns true' do
        expect(o11y_token.send(:new_settings?)).to be true
      end
    end

    context 'when settings are created exactly at the buffer time boundary' do
      let(:o11y_settings) do
        instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: 'https://o11y.example.com',
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 5.minutes.ago
        )
      end

      it 'returns false' do
        expect(o11y_token.send(:new_settings?)).to be false
      end
    end

    context 'when settings are created before the buffer time' do
      let(:o11y_settings) do
        instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: 'https://o11y.example.com',
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 10.minutes.ago
        )
      end

      it 'returns false' do
        expect(o11y_token.send(:new_settings?)).to be false
      end
    end
  end

  describe '.generate_tokens' do
    subject(:generate_tokens) { described_class.generate_tokens(o11y_settings) }

    context 'when authentication is successful' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      end

      it 'returns tokens and user ID' do
        expect(generate_tokens).to eq(
          userId: '123',
          accessJwt: 'access_token_123',
          refreshJwt: 'refresh_token_456'
        )
      end

      it 'makes HTTP request with correct parameters' do
        expect(Gitlab::HTTP).to receive(:post).with(
          'https://o11y.example.com/api/v1/login',
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.dump({
            email: 'test@example.com',
            password: 'password123'
          }),
          allow_local_requests: anything
        ).and_return(http_response)

        generate_tokens
      end
    end

    context 'when o11y_settings is nil' do
      let(:o11y_settings) { nil }

      it 'returns empty hash and logs error' do
        aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Observability::O11yToken::ConfigurationError))

          expect(generate_tokens).to eq({})
        end
      end
    end

    context 'when o11y_settings values are blank' do
      shared_examples 'returns empty hash and logs error' do |field_name|
        it "returns empty hash and logs error when #{field_name} is blank" do
          aggregate_failures do
            expect(Gitlab::ErrorTracking).to receive(:log_exception)
              .with(instance_of(Observability::O11yToken::ConfigurationError))

            expect(generate_tokens).to eq({})
          end
        end
      end

      context 'when o11y_service_url is blank' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: nil,
            o11y_service_user_email: 'test@example.com',
            o11y_service_password: 'password123',
            created_at: 1.hour.ago
          )
        end

        include_examples 'returns empty hash and logs error', 'o11y_service_url'
      end

      context 'when o11y_service_user_email is blank' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: 'https://o11y.example.com',
            o11y_service_user_email: nil,
            o11y_service_password: 'password123',
            created_at: 1.hour.ago
          )
        end

        include_examples 'returns empty hash and logs error', 'o11y_service_user_email'
      end

      context 'when o11y_service_password is blank' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: 'https://o11y.example.com',
            o11y_service_user_email: 'test@example.com',
            o11y_service_password: nil,
            created_at: 1.hour.ago
          )
        end

        include_examples 'returns empty hash and logs error', 'o11y_service_password'
      end

      context 'when all o11y_settings values are blank' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: nil,
            o11y_service_user_email: nil,
            o11y_service_password: nil,
            created_at: 1.hour.ago
          )
        end

        include_examples 'returns empty hash and logs error', 'all fields'
      end
    end

    context 'when HTTP request fails' do
      before do
        allow(Gitlab::HTTP).to receive(:post)
          .and_raise(SocketError.new('Connection failed'))
      end

      it 'returns empty hash and logs error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Observability::O11yToken::NetworkError))

        expect(generate_tokens).to eq({})
      end
    end

    context 'when response is not successful' do
      context 'when response code is 500 and settings are new' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: 'https://o11y.example.com',
            o11y_service_user_email: 'test@example.com',
            o11y_service_password: 'password123',
            created_at: 2.minutes.ago
          )
        end

        let(:http_response) do
          instance_double(HTTParty::Response, code: '500', body: 'Internal Server Error')
        end

        before do
          allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
        end

        it 'returns provisioning status without logging warning' do
          aggregate_failures do
            expect(Gitlab::AppLogger).not_to receive(:warn)
            expect(generate_tokens).to eq({ status: :provisioning })
          end
        end
      end

      context 'when response code is 500 and settings are not new' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: 'https://o11y.example.com',
            o11y_service_user_email: 'test@example.com',
            o11y_service_password: 'password123',
            created_at: 10.minutes.ago
          )
        end

        let(:http_response) do
          instance_double(HTTParty::Response, code: '500', body: 'Internal Server Error')
        end

        before do
          allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
        end

        it 'returns empty hash and logs warning' do
          aggregate_failures do
            expect(Gitlab::AppLogger).to receive(:warn)
              .with("O11y authentication failed with status 500")

            expect(generate_tokens).to eq({})
          end
        end
      end

      context 'when response code is not 500' do
        let(:http_response) do
          instance_double(HTTParty::Response, code: '401', body: 'Unauthorized')
        end

        before do
          allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
        end

        it 'returns empty hash and logs warning' do
          aggregate_failures do
            expect(Gitlab::AppLogger).to receive(:warn)
              .with("O11y authentication failed with status 401")

            expect(generate_tokens).to eq({})
          end
        end
      end
    end

    context 'when response body is invalid JSON' do
      let(:http_response) do
        instance_double(HTTParty::Response, code: 200, body: 'invalid json')
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      end

      it 'returns empty hash and logs error' do
        aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Observability::O11yToken::AuthenticationError))

          expect(generate_tokens).to eq({})
        end
      end
    end

    context 'when response body is nil' do
      let(:http_response) do
        instance_double(HTTParty::Response, code: 200, body: nil)
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      end

      it 'returns empty hash and logs error' do
        aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Observability::O11yToken::AuthenticationError))

          expect(generate_tokens).to eq({})
        end
      end
    end

    context 'when response body is blank' do
      [
        { description: 'when body is empty string', body: '' },
        { description: 'when body is whitespace only', body: '   ' },
        { description: 'when body is newline only', body: "\n" },
        { description: 'when body is tab only', body: "\t" }
      ].each do |test_case|
        context test_case[:description] do
          let(:http_response) do
            instance_double(HTTParty::Response, code: 200, body: test_case[:body])
          end

          before do
            allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
          end

          it 'returns empty hash and logs error' do
            aggregate_failures do
              expect(Gitlab::ErrorTracking).to receive(:log_exception)
                .with(instance_of(Observability::O11yToken::AuthenticationError))

              expect(generate_tokens).to eq({})
            end
          end
        end
      end
    end
  end

  describe '#initialize' do
    subject(:o11y_token) { described_class.new(o11y_settings) }

    it 'creates instance with o11y_settings' do
      allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      expect { o11y_token.generate_tokens }.not_to raise_error
    end
  end

  describe '#parse_response' do
    subject(:o11y_token) { described_class.new(o11y_settings) }

    context 'when response code is 500 and settings are new' do
      let(:o11y_settings) do
        instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: 'https://o11y.example.com',
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 2.minutes.ago
        )
      end

      let(:http_response) do
        instance_double(HTTParty::Response, code: '500', body: 'Internal Server Error')
      end

      it 'returns provisioning status' do
        result = o11y_token.send(:parse_response, http_response)
        expect(result).to eq({ status: :provisioning })
      end
    end

    context 'when response code is 500 and settings are not new' do
      let(:o11y_settings) do
        instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: 'https://o11y.example.com',
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 10.minutes.ago
        )
      end

      let(:http_response) do
        instance_double(HTTParty::Response, code: '500', body: 'Internal Server Error')
      end

      it 'logs warning and returns empty hash' do
        expect(Gitlab::AppLogger).to receive(:warn)
          .with("O11y authentication failed with status 500")

        result = o11y_token.send(:parse_response, http_response)
        expect(result).to eq({})
      end
    end

    context 'when response code is 200' do
      let(:http_response) do
        instance_double(
          HTTParty::Response,
          code: 200,
          body: Gitlab::Json.dump(success_response)
        )
      end

      it 'parses successful response' do
        result = o11y_token.send(:parse_response, http_response)
        expect(result).to eq(
          userId: '123',
          accessJwt: 'access_token_123',
          refreshJwt: 'refresh_token_456'
        )
      end
    end

    context 'when response code is 401' do
      let(:http_response) do
        instance_double(HTTParty::Response, code: '401', body: 'Unauthorized')
      end

      it 'logs warning and returns empty hash' do
        expect(Gitlab::AppLogger).to receive(:warn)
          .with("O11y authentication failed with status 401")

        result = o11y_token.send(:parse_response, http_response)
        expect(result).to eq({})
      end
    end
  end

  describe '#login_url' do
    subject(:o11y_token) { described_class.new(o11y_settings) }

    it 'returns a valid URL that points to the login endpoint' do
      login_url = o11y_token.send(:login_url)

      aggregate_failures do
        expect(login_url).to be_a(String)
        expect(login_url).to include('/api/v1/login')
        expect { URI.parse(login_url) }.not_to raise_error
      end
    end

    it 'preserves the base URL structure while appending the login path' do
      login_url = o11y_token.send(:login_url)
      parsed_url = URI.parse(login_url)

      aggregate_failures do
        expect(parsed_url.host).to eq('o11y.example.com')
        expect(parsed_url.scheme).to eq('https')
        expect(parsed_url.path).to eq('/api/v1/login')
      end
    end

    it 'handles various base URL formats correctly' do
      [
        'https://o11y.example.com',
        'https://o11y.example.com/',
        'https://o11y.example.com/api',
        'https://o11y.example.com/api/',
        'http://localhost:3000',
        'https://o11y.example.com:8080'
      ].each do |base_url|
        o11y_settings = instance_double(
          Observability::GroupO11ySetting,
          o11y_service_url: base_url,
          o11y_service_user_email: 'test@example.com',
          o11y_service_password: 'password123',
          created_at: 1.hour.ago
        )
        o11y_token = described_class.new(o11y_settings)

        login_url = o11y_token.send(:login_url)

        aggregate_failures do
          expect { URI.parse(login_url) }.not_to raise_error
          expect(login_url).to include('/api/v1/login')
        end
      end
    end
  end

  describe Observability::O11yToken::TokenResponse do
    let(:token_response) do
      described_class.new(
        user_id: '123',
        access_jwt: 'access_token',
        refresh_jwt: 'refresh_token'
      )
    end

    describe '#to_h' do
      it 'returns hash with correct keys' do
        expect(token_response.to_h).to eq(
          userId: '123',
          accessJwt: 'access_token',
          refreshJwt: 'refresh_token'
        )
      end
    end

    describe '.from_json' do
      let(:json_data) do
        {
          'data' => {
            'userId' => '456',
            'accessJwt' => 'new_access_token',
            'refreshJwt' => 'new_refresh_token'
          }
        }
      end

      it 'creates TokenResponse from JSON data' do
        result = described_class.from_json(json_data)

        aggregate_failures do
          expect(result.user_id).to eq('456')
          expect(result.access_jwt).to eq('new_access_token')
          expect(result.refresh_jwt).to eq('new_refresh_token')
        end
      end

      context 'when data is missing' do
        [
          { description: 'when json_data is empty hash', data: {} },
          { description: 'when json_data is nil', data: nil }
        ].each do |test_case|
          context test_case[:description] do
            let(:json_data) { test_case[:data] }

            it 'creates TokenResponse with nil values' do
              result = described_class.from_json(json_data)

              aggregate_failures do
                expect(result.user_id).to be_nil
                expect(result.access_jwt).to be_nil
                expect(result.refresh_jwt).to be_nil
              end
            end
          end
        end
      end
    end
  end

  describe Observability::O11yToken::HttpClient do
    let(:http_client) { described_class.new }

    describe '#post' do
      let(:url) { 'https://example.com/api/login' }
      let(:payload) { { email: 'test@example.com', password: 'password' } }

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      end

      it 'makes HTTP POST request' do
        expect(Gitlab::HTTP).to receive(:post).with(
          url,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.dump(payload),
          allow_local_requests: anything
        ).and_return(http_response)

        http_client.post(url, payload)
      end
    end

    describe '#allow_local_requests?' do
      context 'in development environment' do
        before do
          allow(Rails.env).to receive_messages(development?: true, test?: false)
        end

        it 'returns true' do
          expect(http_client.send(:allow_local_requests?)).to be true
        end
      end

      context 'in test environment' do
        before do
          allow(Rails.env).to receive_messages(development?: false, test?: true)
        end

        it 'returns true' do
          expect(Gitlab::HTTP).to receive(:post).with(
            anything,
            hash_including(allow_local_requests: true)
          )
          http_client.post('http://example.com', {})
        end
      end

      context 'in production environment' do
        before do
          allow(Rails.env).to receive_messages(development?: false, test?: false)
        end

        it 'returns false' do
          expect(http_client.send(:allow_local_requests?)).to be false
        end
      end
    end
  end
end
