# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RelationshipsClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  describe '#assign_roles' do
    let(:organization_uuid) { Gitlab::Utils.uuid_v7 }
    let(:resource_id) { '019ed9d4-0000-7000-8000-000000000000' }
    let(:other_resource_id) { '019ed9d4-0000-7000-8000-000000000001' }
    let(:role_id) { Gitlab::Utils.uuid_v7 }
    let(:user_token) { 'user-token' }
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

        ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
      end

      client.assign_roles(assignments, organization_uuid: organization_uuid, token: user_token)
    end
  end

  describe '#write_relationships' do
    let(:user_token) { 'user-token' }
    let(:iam_secret) { 'test-service-token' }
    let(:update_stub) { instance_double(::Gitlab::Iam::Update::V1::UpdateService::Stub) }
    let(:response) { ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new }

    before do
      allow(Authn::IamDataAccessService).to receive_messages(
        grpc_address: 'localhost:5005',
        secret: iam_secret
      )
      allow(::Gitlab::Iam::Update::V1::UpdateService::Stub).to receive(:new).and_return(update_stub)
    end

    it 'sends the caller bearer token as metadata' do
      expect(update_stub).to receive(:write_relationships).with(
        an_instance_of(::Gitlab::Iam::Update::V1::WriteRelationshipsRequest),
        metadata: { 'authorization' => "Bearer #{user_token}" }
      ).and_return(response)

      client.write_relationships([], token: user_token)
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

          expect { client.write_relationships([], token: user_token) }
            .to raise_error(described_class::RequestError, /write failed/) { |e| expect(e.reason).to eq(reason) }
        end
      end

      it 'falls back to the :unknown reason for an unmapped status' do
        allow(update_stub).to receive(:write_relationships).and_raise(GRPC::Internal.new)

        expect { client.write_relationships([], token: user_token) }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unknown) }
      end

      it 'tracks the underlying gRPC exception' do
        error = GRPC::PermissionDenied.new
        allow(update_stub).to receive(:write_relationships).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

        expect { client.write_relationships([], token: user_token) }
          .to raise_error(described_class::RequestError)
      end
    end

    context 'when the data access service is misconfigured' do
      it 'raises a RequestError with the :unavailable reason' do
        allow(Authn::IamDataAccessService).to receive(:grpc_address)
          .and_raise(Authn::IamDataAccessService::ConfigurationError)

        expect { client.write_relationships([], token: user_token) }
          .to raise_error(described_class::RequestError) { |e| expect(e.reason).to eq(:unavailable) }
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
          response
        end

        client.write_relationships([], token: user_token)

        # a_hash_including, not eq: the real interceptor chain also carries
        # Labkit's correlation-id interceptor, which adds its own header.
        expect(received_metadata).to include(
          'authorization' => "Bearer #{user_token}",
          Authn::IamDataAccessService::SERVICE_TOKEN_HEADER => iam_secret
        )
      end
    end
  end

  describe 'insecure channel guard' do
    it 'refuses an insecure channel outside development and test' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      allow(Authn::IamDataAccessService).to receive(:grpc_address).and_return('localhost:5005')

      expect { client.write_relationships([], token: 'tok') }
        .to raise_error(Authn::IamService::BaseClient::InsecureChannelError)
    end
  end
end
