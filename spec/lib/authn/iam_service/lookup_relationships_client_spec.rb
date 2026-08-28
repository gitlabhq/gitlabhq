# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::LookupRelationshipsClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:user_token) { 'user-token' }
  let(:iam_secret) { 'test-service-token' }
  let(:lookup_stub) { instance_double(::Gitlab::Iam::Lookup::V1::LookupService::Stub) }
  let(:response) { ::Gitlab::Iam::Lookup::V1::LookupRelationshipsResponse.new }

  let(:resource_id) { Gitlab::Utils.uuid_v7 }
  let(:ancestor_id) { Gitlab::Utils.uuid_v7 }
  let(:role_id) { Gitlab::Utils.uuid_v7 }

  before do
    allow(Authn::IamDataAccessService).to receive_messages(
      grpc_address: 'localhost:5005',
      grpc_secure?: false,
      secret: iam_secret
    )
    allow(::Gitlab::Iam::Lookup::V1::LookupService::Stub).to receive(:new).and_return(lookup_stub)
    allow(lookup_stub).to receive(:lookup_relationships).and_return(response)
  end

  def lookup(**overrides)
    client.lookup(**{
      objects: [{ id: resource_id, ancestor_ids: [ancestor_id] }],
      kinds: [:KIND_ASSIGNMENT],
      role_ids: [role_id],
      page_size: 50,
      page_token: 'cursor',
      token: user_token
    }.merge(overrides))
  end

  describe '#lookup' do
    it 'builds the request from the objects, filter, and pagination and sends the bearer token', :aggregate_failures do
      expect(lookup_stub).to receive(:lookup_relationships) do |request, metadata:|
        expect(metadata).to eq('authorization' => "Bearer #{user_token}")

        expect(request.objects.map(&:id)).to eq([resource_id])
        expect(request.objects.first.ancestors.map(&:id)).to eq([ancestor_id])
        expect(request.filter.kinds).to eq([:KIND_ASSIGNMENT])
        expect(request.filter.roles.map(&:id)).to eq([role_id])
        expect(request.page_size).to eq(50)
        expect(request.page_token).to eq('cursor')

        response
      end

      expect(lookup).to eq(response)
    end

    it 'defaults page_size and page_token when not given', :aggregate_failures do
      expect(lookup_stub).to receive(:lookup_relationships) do |request, _metadata|
        expect(request.page_size).to eq(0)
        expect(request.page_token).to eq('')

        response
      end

      lookup(page_size: nil, page_token: nil)
    end

    context 'when the IAM lookup fails with a gRPC status' do
      # Each gRPC error IAM can return maps to a machine-readable reason the
      # caller translates; the client stays transport-only.
      {
        GRPC::NotFound => :not_found,
        GRPC::PermissionDenied => :permission_denied,
        GRPC::Unauthenticated => :unauthenticated,
        GRPC::InvalidArgument => :invalid_request,
        GRPC::Unavailable => :unavailable,
        GRPC::DeadlineExceeded => :timeout
      }.each do |error_class, reason|
        it "raises a RequestError with reason #{reason} for #{error_class}" do
          allow(lookup_stub).to receive(:lookup_relationships).and_raise(error_class.new)

          expect { lookup }
            .to raise_error(described_class::RequestError, /lookup failed/) { |e| expect(e.reason).to eq(reason) }
        end
      end

      it 'falls back to the :unknown reason for an unmapped status' do
        allow(lookup_stub).to receive(:lookup_relationships).and_raise(GRPC::Internal.new)

        expect { lookup }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unknown) }
      end

      it 'tracks the underlying gRPC exception' do
        error = GRPC::NotFound.new
        allow(lookup_stub).to receive(:lookup_relationships).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { lookup }.to raise_error(described_class::RequestError)
      end
    end

    context 'when the data access service is misconfigured' do
      it 'raises a RequestError with the :unavailable reason' do
        allow(Authn::IamDataAccessService).to receive(:grpc_address)
          .and_raise(Authn::IamDataAccessService::ConfigurationError)

        expect { lookup }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unavailable) }
      end

      it 'tracks the underlying configuration error' do
        error = Authn::IamDataAccessService::ConfigurationError.new
        allow(Authn::IamDataAccessService).to receive(:grpc_address).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { lookup }.to raise_error(described_class::RequestError)
      end
    end

    context 'with a real stub and interceptor chain' do
      # Everything up to the stub is unmocked here (including
      # ServiceTokenInterceptor and GRPC::ClientStub#request_response) so the
      # real interceptor dispatch runs; only the network-facing ActiveCall is
      # replaced, so no actual connection is attempted.
      let(:fake_active_call) { instance_double(GRPC::ActiveCall) }

      before do
        allow(::Gitlab::Iam::Lookup::V1::LookupService::Stub).to receive(:new).and_call_original
        allow(GRPC::ActiveCall).to receive(:new).and_return(fake_active_call)
        allow(fake_active_call).to receive(:interceptable).and_return(fake_active_call)
      end

      it 'delivers the service token header on the actual outbound gRPC call' do
        received_metadata = nil
        allow(fake_active_call).to receive(:request_response) do |_request, metadata:|
          received_metadata = metadata
          response
        end

        lookup

        # a_hash_including, not eq: the real interceptor chain also carries
        # Labkit's correlation-id interceptor, which adds its own header.
        expect(received_metadata).to include(
          'authorization' => "Bearer #{user_token}",
          Authn::IamDataAccessService::SERVICE_TOKEN_HEADER => iam_secret
        )
      end
    end
  end

  describe 'channel transport' do
    let(:tls_credentials) { instance_double(GRPC::Core::ChannelCredentials) }
    let(:insecure_log) { a_hash_including(message: 'Using an insecure IAM gRPC channel', address: 'iam.test:5005') }

    before do
      Authn::IamService::BaseClient::LOGGED_INSECURE_ENDPOINTS.clear

      allow(Authn::IamDataAccessService).to receive(:grpc_address).and_return('iam.test:5005')
      allow(::Gitlab::X509::Certificate).to receive(:ca_certs_bundle).and_return('cert-data')
      allow(GRPC::Core::ChannelCredentials).to receive(:new).with('cert-data').and_return(tls_credentials)
      allow(Gitlab::AppLogger).to receive(:info)
    end

    context 'when the data access service is secure' do
      before do
        allow(Authn::IamDataAccessService).to receive(:grpc_secure?).and_return(true)
      end

      it 'builds the stub with TLS credentials' do
        lookup

        expect(::Gitlab::Iam::Lookup::V1::LookupService::Stub)
          .to have_received(:new).with('iam.test:5005', tls_credentials, any_args)
      end

      it 'does not log a plain text endpoint' do
        lookup

        expect(Gitlab::AppLogger).not_to have_received(:info).with(insecure_log)
      end
    end

    context 'when the data access service is not secure' do
      before do
        allow(Authn::IamDataAccessService).to receive(:grpc_secure?).and_return(false)
      end

      it 'builds the stub with a plain text channel' do
        lookup

        expect(::Gitlab::Iam::Lookup::V1::LookupService::Stub)
          .to have_received(:new).with('iam.test:5005', :this_channel_is_insecure, any_args)
      end

      it 'logs the plain text endpoint' do
        lookup

        expect(Gitlab::AppLogger).to have_received(:info).with(insecure_log).once
      end

      it 'logs the endpoint only once per process' do
        3.times { lookup }

        expect(Gitlab::AppLogger).to have_received(:info).with(insecure_log).once
      end
    end
  end
end
