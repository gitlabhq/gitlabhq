# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::O11yToken, feature_category: :observability do
  let(:o11y_settings) do
    instance_double(
      Observability::GroupO11ySetting,
      o11y_service_url: 'https://o11y.example.com',
      o11y_service_user_email: 'test@example.com',
      o11y_service_password: 'password123'
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
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Observability::O11yToken::ConfigurationError))

        expect(generate_tokens).to eq({})
      end
    end

    context 'when o11y_settings values are blank' do
      shared_examples 'returns empty hash and logs error' do |field_name|
        it "returns empty hash and logs error when #{field_name} is blank" do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Observability::O11yToken::ConfigurationError))

          expect(generate_tokens).to eq({})
        end
      end

      context 'when o11y_service_url is blank' do
        let(:o11y_settings) do
          instance_double(
            Observability::GroupO11ySetting,
            o11y_service_url: nil,
            o11y_service_user_email: 'test@example.com',
            o11y_service_password: 'password123'
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
            o11y_service_password: 'password123'
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
            o11y_service_password: nil
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
            o11y_service_password: nil
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
      let(:http_response) do
        instance_double(HTTParty::Response, code: '401', body: 'Unauthorized')
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(http_response)
      end

      it 'returns empty hash and logs warning' do
        expect(Gitlab::AppLogger).to receive(:warn)
          .with("O11y authentication failed with status 401")

        expect(generate_tokens).to eq({})
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
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Observability::O11yToken::AuthenticationError))

        expect(generate_tokens).to eq({})
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
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Observability::O11yToken::AuthenticationError))

        expect(generate_tokens).to eq({})
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
            expect(Gitlab::ErrorTracking).to receive(:log_exception)
              .with(instance_of(Observability::O11yToken::AuthenticationError))

            expect(generate_tokens).to eq({})
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

        expect(result.user_id).to eq('456')
        expect(result.access_jwt).to eq('new_access_token')
        expect(result.refresh_jwt).to eq('new_refresh_token')
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

              expect(result.user_id).to be_nil
              expect(result.access_jwt).to be_nil
              expect(result.refresh_jwt).to be_nil
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
