# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::UpdateRelationshipsClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:organization_uuid) { Gitlab::Utils.uuid_v7 }
  let(:resource_id) { '019ed9d4-0000-7000-8000-000000000000' }
  let(:other_resource_id) { '019ed9d4-0000-7000-8000-000000000001' }
  let(:user_token) { 'user-token' }
  let(:iam_secret) { 'test-service-token' }
  let(:update_stub) { instance_double(::Gitlab::Iam::Update::V1::UpdateService::Stub) }
  let(:write_response) { ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new }
  let(:delete_response) { ::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new }

  describe '#grant_roles' do
    let(:role_id) { Gitlab::Utils.uuid_v7 }
    let(:assignments) do
      [
        { assignee_id: 2, resource_id: resource_id, role_id: role_id },
        { assignee_id: 3, resource_id: other_resource_id, role_id: role_id }
      ]
    end

    it 'writes one ASSIGNMENT tuple per assignment, all scoped to the org', :aggregate_failures do
      expect(client).to receive(:write_relationships) do |inputs, token:|
        expect(token).to eq(user_token)
        expect(inputs.size).to eq(2)
        expect(inputs.map { |i| i.subject.identity.origin }).to all(eq(:ORIGIN_ORGANIZATION))
        expect(inputs.map { |i| i.subject.identity.origin_id }).to all(eq(organization_uuid))
        expect(inputs.map { |i| [i.subject.identity.local_id, i.object.id] })
          .to match_array([['2', resource_id], ['3', other_resource_id]])
        expect(inputs.map(&:kind)).to all(eq(:KIND_ASSIGNMENT))
        expect(inputs.map { |i| i.role.id }).to all(eq(role_id))

        write_response
      end

      client.grant_roles(assignments, organization_uuid: organization_uuid, token: user_token)
    end
  end

  describe '#revoke_roles' do
    let(:keys) do
      [
        { assignee_id: 2, resource_id: resource_id },
        { assignee_id: 3, resource_id: other_resource_id }
      ]
    end

    it 'deletes one ASSIGNMENT key per entry, all scoped to the org', :aggregate_failures do
      expect(client).to receive(:delete_relationships) do |inputs, token:|
        expect(token).to eq(user_token)
        expect(inputs.size).to eq(2)
        expect(inputs.map { |i| i.subject.identity.origin }).to all(eq(:ORIGIN_ORGANIZATION))
        expect(inputs.map { |i| i.subject.identity.origin_id }).to all(eq(organization_uuid))
        expect(inputs.map { |i| [i.subject.identity.local_id, i.object.id] })
          .to match_array([['2', resource_id], ['3', other_resource_id]])
        expect(inputs.map(&:kind)).to all(eq(:KIND_ASSIGNMENT))

        delete_response
      end

      client.revoke_roles(keys, organization_uuid: organization_uuid, token: user_token)
    end
  end

  describe '#grant_roles request metadata and error handling' do
    subject(:grant) { client.grant_roles([], organization_uuid: organization_uuid, token: user_token) }

    before do
      allow(Authn::IamDataAccessService).to receive_messages(
        grpc_address: 'localhost:5005',
        grpc_secure?: false,
        secret: iam_secret
      )
      allow(::Gitlab::Iam::Update::V1::UpdateService::Stub).to receive(:new).and_return(update_stub)
    end

    it 'sends the caller bearer token as metadata' do
      expect(update_stub).to receive(:write_relationships).with(
        an_instance_of(::Gitlab::Iam::Update::V1::WriteRelationshipsRequest),
        metadata: { 'authorization' => "Bearer #{user_token}" }
      ).and_return(write_response)

      grant
    end

    context 'when the IAM write fails with a gRPC status' do
      # Each gRPC error IAM can return maps to a machine-readable reason the
      # caller translates; the client stays transport-only.
      {
        GRPC::PermissionDenied => :permission_denied,
        GRPC::Unauthenticated => :unauthenticated,
        GRPC::InvalidArgument => :invalid_request,
        GRPC::Unavailable => :unavailable,
        GRPC::DeadlineExceeded => :timeout
      }.each do |error_class, reason|
        it "raises a RequestError with reason #{reason} for #{error_class}" do
          allow(update_stub).to receive(:write_relationships).and_raise(error_class.new)

          expect { grant }
            .to raise_error(described_class::RequestError, /write failed/) { |e| expect(e.reason).to eq(reason) }
        end
      end

      it 'falls back to the :unknown reason for an unmapped status' do
        allow(update_stub).to receive(:write_relationships).and_raise(GRPC::Internal.new)

        expect { grant }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unknown) }
      end

      it 'tracks the underlying gRPC exception' do
        error = GRPC::PermissionDenied.new
        allow(update_stub).to receive(:write_relationships).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { grant }.to raise_error(described_class::RequestError)
      end
    end

    context 'when the data access service is misconfigured' do
      it 'raises a RequestError with the :unavailable reason' do
        allow(Authn::IamDataAccessService).to receive(:grpc_address)
          .and_raise(Authn::IamDataAccessService::ConfigurationError)

        expect { grant }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unavailable) }
      end

      it 'tracks the underlying configuration error' do
        error = Authn::IamDataAccessService::ConfigurationError.new
        allow(Authn::IamDataAccessService).to receive(:grpc_address).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { grant }.to raise_error(described_class::RequestError)
      end
    end

    context 'with a real stub and interceptor chain' do
      # Everything up to the stub is unmocked here (including
      # ServiceTokenInterceptor and GRPC::ClientStub#request_response) so the
      # real interceptor dispatch runs; only the network-facing ActiveCall is
      # replaced, so no actual connection is attempted.
      let(:fake_active_call) { instance_double(GRPC::ActiveCall) }

      before do
        allow(::Gitlab::Iam::Update::V1::UpdateService::Stub).to receive(:new).and_call_original
        allow(GRPC::ActiveCall).to receive(:new).and_return(fake_active_call)
        allow(fake_active_call).to receive(:interceptable).and_return(fake_active_call)
      end

      it 'delivers the service token header on the actual outbound gRPC call' do
        received_metadata = nil
        allow(fake_active_call).to receive(:request_response) do |_request, metadata:|
          received_metadata = metadata
          write_response
        end

        grant

        # a_hash_including, not eq: the real interceptor chain also carries
        # Labkit's correlation-id interceptor, which adds its own header.
        expect(received_metadata).to include(
          'authorization' => "Bearer #{user_token}",
          Authn::IamDataAccessService::SERVICE_TOKEN_HEADER => iam_secret
        )
      end
    end
  end

  describe '#revoke_roles request metadata and error handling' do
    subject(:revoke) { client.revoke_roles([], organization_uuid: organization_uuid, token: user_token) }

    before do
      allow(Authn::IamDataAccessService).to receive_messages(
        grpc_address: 'localhost:5005',
        grpc_secure?: false,
        secret: iam_secret
      )
      allow(::Gitlab::Iam::Update::V1::UpdateService::Stub).to receive(:new).and_return(update_stub)
    end

    it 'sends the caller bearer token as metadata' do
      expect(update_stub).to receive(:delete_relationships).with(
        an_instance_of(::Gitlab::Iam::Update::V1::DeleteRelationshipsRequest),
        metadata: { 'authorization' => "Bearer #{user_token}" }
      ).and_return(delete_response)

      revoke
    end

    context 'when the IAM delete fails with a gRPC status' do
      {
        GRPC::PermissionDenied => :permission_denied,
        GRPC::Unauthenticated => :unauthenticated,
        GRPC::InvalidArgument => :invalid_request,
        GRPC::Unavailable => :unavailable,
        GRPC::DeadlineExceeded => :timeout
      }.each do |error_class, reason|
        it "raises a RequestError with reason #{reason} for #{error_class}" do
          allow(update_stub).to receive(:delete_relationships).and_raise(error_class.new)

          expect { revoke }
            .to raise_error(described_class::RequestError, /delete failed/) { |e| expect(e.reason).to eq(reason) }
        end
      end

      it 'tracks the underlying gRPC exception' do
        error = GRPC::PermissionDenied.new
        allow(update_stub).to receive(:delete_relationships).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { revoke }.to raise_error(described_class::RequestError)
      end
    end

    context 'when the data access service is misconfigured' do
      it 'raises a RequestError with the :unavailable reason' do
        allow(Authn::IamDataAccessService).to receive(:grpc_address)
          .and_raise(Authn::IamDataAccessService::ConfigurationError)

        expect { revoke }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unavailable) }
      end
    end
  end

  describe 'channel transport' do
    let(:tls_credentials) { instance_double(GRPC::Core::ChannelCredentials) }

    before do
      allow(Authn::IamDataAccessService).to receive_messages(
        grpc_address: 'iam.test:5005',
        secret: iam_secret
      )
      allow(::Gitlab::X509::Certificate).to receive(:ca_certs_bundle).and_return('cert-data')
      allow(GRPC::Core::ChannelCredentials).to receive(:new).with('cert-data').and_return(tls_credentials)
      allow(::Gitlab::Iam::Update::V1::UpdateService::Stub).to receive(:new).and_return(update_stub)
      allow(update_stub).to receive(:write_relationships).and_return(write_response)
    end

    it 'builds the stub with TLS credentials when the data access service is secure' do
      allow(Authn::IamDataAccessService).to receive(:grpc_secure?).and_return(true)

      client.grant_roles([], organization_uuid: organization_uuid, token: 'tok')

      expect(::Gitlab::Iam::Update::V1::UpdateService::Stub)
        .to have_received(:new).with('iam.test:5005', tls_credentials, any_args)
    end

    it 'builds the stub with a plain text channel when the data access service is not secure' do
      allow(Authn::IamDataAccessService).to receive(:grpc_secure?).and_return(false)

      client.grant_roles([], organization_uuid: organization_uuid, token: 'tok')

      expect(::Gitlab::Iam::Update::V1::UpdateService::Stub)
        .to have_received(:new).with('iam.test:5005', :this_channel_is_insecure, any_args)
    end
  end
end
