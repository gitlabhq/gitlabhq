# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::GrpcClient, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  subject(:client) { described_class.new }

  let(:iam_service_address) { 'localhost:5004' }
  let(:iam_secret) { 'test-secret-token' }

  let(:auth_stub) { instance_double(::Gitlab::Iam::Auth::V1::AuthService::Stub) }
  let(:login_stub) { instance_double(::Gitlab::Iam::Auth::V1::LoginService::Stub) }
  let(:consent_stub) { instance_double(::Gitlab::Iam::Auth::V1::ConsentService::Stub) }

  before do
    allow(Authn::IamAuthService).to receive_messages(
      grpc_address: iam_service_address,
      secret: iam_secret
    )

    allow(::Gitlab::Iam::Auth::V1::AuthService::Stub).to receive(:new).and_return(auth_stub)
    allow(::Gitlab::Iam::Auth::V1::LoginService::Stub).to receive(:new).and_return(login_stub)
    allow(::Gitlab::Iam::Auth::V1::ConsentService::Stub).to receive(:new).and_return(consent_stub)
  end

  describe 'gRPC calls' do
    where(:method, :rpc_method, :stub_let, :request_class, :response_class, :params) do
      :health                   | :health | :auth_stub    | ::Gitlab::Iam::Auth::V1::HealthRequest               | ::Gitlab::Iam::Auth::V1::HealthResponse               | {}
      :accept_login_challenge   | :accept | :login_stub   | ::Gitlab::Iam::Auth::V1::LoginServiceAcceptRequest   | ::Gitlab::Iam::Auth::V1::LoginServiceAcceptResponse   | { challenge: 'test-challenge', subject: '42', name: 'Jane Doe', email: 'jane.doe@example.com' }
      :get_consent_challenge    | :get    | :consent_stub | ::Gitlab::Iam::Auth::V1::ConsentServiceGetRequest    | ::Gitlab::Iam::Auth::V1::ConsentServiceGetResponse    | { challenge: 'test-challenge' }
      :accept_consent_challenge | :accept | :consent_stub | ::Gitlab::Iam::Auth::V1::ConsentServiceAcceptRequest | ::Gitlab::Iam::Auth::V1::ConsentServiceAcceptResponse | { challenge: 'test-challenge', granted_scopes: %w[openid profile] }
      :reject_consent_challenge | :reject | :consent_stub | ::Gitlab::Iam::Auth::V1::ConsentServiceRejectRequest | ::Gitlab::Iam::Auth::V1::ConsentServiceRejectResponse | { challenge: 'test-challenge' }
    end

    with_them do
      let(:stub) { send(stub_let) }
      let(:response) { response_class.new }

      it 'sends the request with the routing header and returns the response', :aggregate_failures do
        expect(stub).to receive(rpc_method).with(
          an_instance_of(request_class),
          metadata: a_hash_including('x-gitlab-svc' => 'iam-auth-grpc')
        ).and_return(response)

        expect(client.public_send(method, **params)).to eq(response)
      end
    end
  end

  describe 'service token' do
    context 'with a real stub and interceptor chain' do
      # Everything up to the stub is unmocked here (including
      # ServiceTokenInterceptor and GRPC::ClientStub#request_response) so the
      # real interceptor dispatch runs; only the network-facing ActiveCall is
      # replaced, so no actual connection is attempted.
      let(:fake_active_call) { instance_double(GRPC::ActiveCall) }

      before do
        allow(::Gitlab::Iam::Auth::V1::AuthService::Stub).to receive(:new).and_call_original
        allow(GRPC::ActiveCall).to receive(:new).and_return(fake_active_call)
        allow(fake_active_call).to receive(:interceptable).and_return(fake_active_call)
      end

      it 'delivers the service token and routing headers on the actual outbound gRPC call' do
        received_metadata = nil
        allow(fake_active_call).to receive(:request_response) do |_request, metadata:|
          received_metadata = metadata
          ::Gitlab::Iam::Auth::V1::HealthResponse.new
        end

        client.health

        # a_hash_including, not eq: the real interceptor chain also carries
        # Labkit's correlation-id interceptor, which adds its own header.
        expect(received_metadata).to include(
          'x-gitlab-svc' => 'iam-auth-grpc',
          Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret
        )
      end
    end
  end

  describe 'error handling' do
    before do
      allow(Gitlab::ErrorTracking).to receive(:track_exception)
      allow(auth_stub).to receive(:health).and_raise(error)
    end

    context 'when the IAM service is misconfigured' do
      let(:error) { Authn::IamAuthService::ConfigurationError.new('IAM service is not configured') }

      it 'raises RequestError with the configuration message and skips Sentry', :aggregate_failures do
        expect { client.health }.to raise_error(described_class::RequestError, 'IAM service is not configured')
        expect(Gitlab::ErrorTracking).not_to have_received(:track_exception)
      end
    end

    context 'when the gRPC stub raises GRPC::BadStatus' do
      where(:error_class) do
        [GRPC::Unavailable, GRPC::Unauthenticated, GRPC::InvalidArgument]
      end

      with_them do
        let(:error) { error_class.new('upstream details') }

        it 'raises a sanitized RequestError and tracks the exception', :aggregate_failures do
          expect { client.health }.to raise_error(described_class::RequestError, 'Failed to connect to IAM service')
          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(error)
        end
      end
    end
  end

  describe 'channel credentials' do
    where(:address, :expected_endpoint, :expects_tls) do
      'localhost:5004'                  | 'localhost:5004'              | false
      'tls://iam.example.com:5004'      | 'iam.example.com:5004'        | true
      'tcp://iam.example.com:5004'      | 'iam.example.com:5004'        | false
      ':::invalid'                      | ':::invalid'                  | false
    end

    with_them do
      let(:iam_service_address) { address }
      let(:tls_credentials) { instance_double(GRPC::Core::ChannelCredentials) }

      before do
        allow(::Gitlab::X509::Certificate).to receive(:ca_certs_bundle).and_return('cert-data')
        allow(GRPC::Core::ChannelCredentials).to receive(:new).with('cert-data').and_return(tls_credentials)
        allow(auth_stub).to receive(:health).and_return(::Gitlab::Iam::Auth::V1::HealthResponse.new)
      end

      it 'configures the gRPC channel with the expected endpoint and credentials' do
        client.health

        expected_credentials = expects_tls ? tls_credentials : :this_channel_is_insecure
        expect(::Gitlab::Iam::Auth::V1::AuthService::Stub).to have_received(:new).with(
          expected_endpoint,
          expected_credentials,
          interceptors: [
            Labkit::Correlation::GRPC::ClientInterceptor.instance,
            an_instance_of(Authn::IamService::ServiceTokenInterceptor)
          ],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end
  end
end
