# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::OauthApplicationReplicator, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:client) do
    instance_double(Authn::IamService::GrpcClient, create_oauth_application: nil, delete_oauth_application: nil)
  end

  subject(:replicator) { described_class.new(client: client) }

  describe '#deliver' do
    context 'with an upsert event' do
      let_it_be(:application) { create(:oauth_application) }
      let(:row) { build(:iam_outbox, entity_id: application.id) }

      it 'pushes the full field set to IAM' do
        replicator.deliver(row)

        expect(client).to have_received(:create_oauth_application).with(
          client_id: application.uid,
          client_secret: application.secret,
          client_name: application.name,
          redirect_uris: application.redirect_uri.split,
          scopes: application.scopes.to_a,
          public: !application.confidential?,
          trusted: application.trusted?,
          owner: application.owner.name,
          grant_types: %w[authorization_code refresh_token client_credentials],
          response_types: %w[code],
          created_at: Google::Protobuf::Timestamp.new(seconds: application.created_at.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: application.updated_at.to_i)
        )
      end

      it 'replaces the upstream client', :aggregate_failures do
        replicator.deliver(row)

        expect(client).to have_received(:delete_oauth_application).with(client_id: application.uid).ordered
        expect(client).to have_received(:create_oauth_application).ordered
      end

      it 'returns :delivered' do
        expect(replicator.deliver(row)).to eq(:delivered)
      end

      it 'treats a missing upstream client as a first create rather than a failure' do
        allow(client).to receive(:delete_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new('gone', reason: :not_found))

        expect { replicator.deliver(row) }.not_to raise_error
        expect(client).to have_received(:create_oauth_application)
      end

      it 'fails when the replace delete fails for any other reason' do
        allow(client).to receive(:delete_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new('down', reason: :unavailable))

        expect { replicator.deliver(row) }.to raise_error(Authn::IamService::GrpcClient::RequestError)
        expect(client).not_to have_received(:create_oauth_application)
      end

      context 'when the application is not confidential' do
        let(:application) { create(:oauth_application, confidential: false) }

        it 'omits client_credentials and marks the app public' do
          replicator.deliver(row)

          expect(client).to have_received(:create_oauth_application).with(
            hash_including(public: true, grant_types: %w[authorization_code refresh_token])
          )
        end
      end

      context 'when the application has no owner' do
        let(:application) { create(:oauth_application, :without_owner) }

        it 'sends the administrator label' do
          replicator.deliver(row)

          expect(client).to have_received(:create_oauth_application).with(hash_including(owner: 'An administrator'))
        end
      end

      context 'when the application is dynamic' do
        let(:application) { create(:oauth_application, :dynamic) }

        it 'sends the anonymous service label' do
          replicator.deliver(row)

          expect(client).to have_received(:create_oauth_application).with(hash_including(owner: 'An anonymous service'))
        end
      end

      context 'when the application is owned by a group' do
        let(:application) { create(:oauth_application, :group_owned) }

        it 'sends the group name' do
          replicator.deliver(row)

          expect(client).to have_received(:create_oauth_application).with(hash_including(owner: application.owner.name))
        end
      end

      context 'when the application has multiple redirect URIs' do
        let(:application) do
          create(:oauth_application, redirect_uri: "https://a.example.com\nhttps://b.example.com")
        end

        it 'splits them into an array' do
          replicator.deliver(row)

          expect(client).to have_received(:create_oauth_application).with(
            hash_including(redirect_uris: %w[https://a.example.com https://b.example.com])
          )
        end
      end

      context 'when the Rails record is absent' do
        let(:row) { build(:iam_outbox, entity_id: non_existing_record_id) }

        it 'returns :skipped without calling IAM' do
          expect(replicator.deliver(row)).to eq(:skipped)
          expect(client).not_to have_received(:create_oauth_application)
        end
      end
    end

    context 'with a delete event' do
      let(:uid) { build(:oauth_application).uid }
      let(:row) { build(:iam_outbox, event_type: :delete, payload: { 'uid' => uid }) }

      it 'removes via the payload uid' do
        replicator.deliver(row)

        expect(client).to have_received(:delete_oauth_application).with(client_id: uid)
      end

      it 'accepts a symbol-keyed payload' do
        row.payload = { uid: uid }

        replicator.deliver(row)

        expect(client).to have_received(:delete_oauth_application).with(client_id: uid)
      end

      it 'returns :delivered' do
        expect(replicator.deliver(row)).to eq(:delivered)
      end

      it 'raises when the payload has no uid' do
        row.payload = {}

        expect { replicator.deliver(row) }.to raise_error(KeyError)
      end
    end

    context 'with an event_type the replicator does not handle' do
      let(:row) { instance_double(Authn::IamOutbox, event_type: 'unknown') }

      it 'raises' do
        expect { replicator.deliver(row) }.to raise_error(ArgumentError, /unhandled event_type/)
      end
    end
  end
end
