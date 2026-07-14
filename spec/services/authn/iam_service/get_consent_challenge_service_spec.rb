# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::GetConsentChallengeService, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:challenge) { 'a' * 64 }

  let(:grpc_client) { instance_double(Authn::IamService::GrpcClient) }
  let(:service) { described_class.new(challenge: challenge, client: grpc_client) }

  subject(:result) { service.execute }

  describe '#execute' do
    let(:created_at_time) { Time.zone.parse('2025-01-01T00:00:00Z') }
    let(:created_at_timestamp) { Google::Protobuf::Timestamp.new(seconds: created_at_time.to_i) }

    let(:client_attrs) do
      {
        client_id: 'test-app',
        client_name: 'Test App',
        client_owner: 'GitLab User',
        scopes: %w[openid profile email],
        created_at: created_at_timestamp
      }
    end

    let(:response_attrs) do
      {
        skip: false,
        subject: '123',
        requested_scopes: %w[openid profile],
        client: ::Gitlab::Iam::Auth::V1::Client.new(**client_attrs)
      }
    end

    let(:response) { ::Gitlab::Iam::Auth::V1::ConsentServiceGetResponse.new(**response_attrs) }

    before do
      allow(grpc_client).to receive(:get_consent_challenge).and_return(response)
    end

    context 'when the response is valid' do
      it 'returns the flattened consent payload', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload).to eq(
          skip_consent: false,
          subject: '123',
          requested_scopes: %w[openid profile],
          client_id: 'test-app',
          client_name: 'Test App',
          client_owner: 'GitLab User',
          client_created_at: created_at_time,
          client_scopes: %w[openid profile email]
        )
      end

      it 'sends the correct gRPC request' do
        result

        expect(grpc_client).to have_received(:get_consent_challenge).with(challenge: challenge)
      end
    end

    context 'when subject is an integer' do
      let(:response) do
        double( # rubocop:disable RSpec/VerifiedDoubles -- proto subject is string; integer coercion only reachable via stub
          skip: false,
          subject: 123,
          requested_scopes: %w[openid profile],
          client: ::Gitlab::Iam::Auth::V1::Client.new(**client_attrs)
        )
      end

      it 'coerces subject to a string in the payload' do
        expect(result.payload[:subject]).to eq('123')
      end
    end

    context 'when skip is true' do
      let(:response_attrs) { super().merge(skip: true) }

      it 'returns skip_consent as true', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:skip_consent]).to be(true)
      end
    end

    context 'with a missing mandatory field' do
      # Tests a representative subset of MANDATORY_FIELDS to exercise the validation
      # logic. Full per-field coverage will be added alongside richer validation.
      where(:client_overrides, :response_overrides, :missing_field) do
        {}                   | { requested_scopes: [] } | 'requested_scopes'
        { client_id: '' }    | {}                       | 'client_id'
        { client_owner: '' } | {}                       | 'client_owner'
        { scopes: [] }       | {}                       | 'client_scopes'
      end

      with_them do
        let(:client_attrs)   { super().merge(client_overrides) }
        let(:response_attrs) { super().merge(response_overrides) }

        it 'returns an invalid_response error and logs the failure', :aggregate_failures do
          allow(Gitlab::AuthLogger).to receive(:error)

          expect(result).to be_error
          expect(result.reason).to eq(:invalid_response)
          expect(result.message).to eq("IAM consent response missing mandatory fields: #{missing_field}")
          expect(Gitlab::AuthLogger).to have_received(:error)
        end
      end
    end

    context 'when the gRPC client raises a RequestError' do
      before do
        allow(grpc_client).to receive(:get_consent_challenge)
          .and_raise(Authn::IamService::GrpcClient::RequestError, 'Failed to connect to IAM service')
      end

      include_examples 'iam service error response',
        reason: :service_unavailable,
        message: 'Failed to connect to IAM service'
    end
  end
end
