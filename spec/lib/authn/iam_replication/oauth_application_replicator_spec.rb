# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::OauthApplicationReplicator, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:client) do
    instance_double(Authn::IamService::GrpcClient, upsert_oauth_application: nil, delete_oauth_application: nil)
  end

  subject(:replicator) { described_class.new(client: client) }

  describe '#upsert' do
    let_it_be(:application) { create(:oauth_application) }

    it 'pushes the application to IAM and returns :delivered', :aggregate_failures do
      expect(replicator.upsert(application)).to eq(:delivered)
      expect(client).to have_received(:upsert_oauth_application).with(hash_including(client_id: application.uid))
    end

    context 'when the secret is not a SHA-512 digest' do
      where(:secret) { ['$pbkdf2-sha512$20000$$legacy', 'f' * 64] }

      with_them do
        let(:legacy_application) { create(:oauth_application).tap { |app| app.update_column(:secret, secret) } }

        it 'returns :unsupported_secret_digest without calling IAM', :aggregate_failures do
          expect(replicator.upsert(legacy_application)).to eq(:unsupported_secret_digest)
          expect(client).not_to have_received(:upsert_oauth_application)
        end
      end
    end
  end

  describe '#deliver' do
    context 'with an upsert event' do
      let_it_be(:application) { create(:oauth_application) }
      let(:row) { build(:iam_outbox, entity_id: application.id) }

      it 'pushes the full field set to IAM' do
        replicator.deliver(row)

        expect(client).to have_received(:upsert_oauth_application).with(
          client_id: application.uid,
          hashed_client_secret: application.secret,
          redirect_uris: application.redirect_uri.split,
          grant_types: %w[authorization_code refresh_token client_credentials],
          response_types: %w[code],
          scopes: application.scopes.to_a,
          public: !application.confidential?,
          client_name: application.name,
          owner: application.owner.name,
          trusted: application.trusted?,
          created_at: Google::Protobuf::Timestamp.new(seconds: application.created_at.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: application.updated_at.to_i),
          dynamic: false,
          organization_id: application.organization.uuid,
          owning_cell_id: Gitlab.config.cell.id.to_i
        )
      end

      # Pins invariant: Doorkeeper's Sha512Hash output matches IAM's
      # ^[0-9a-f]{128}$ pattern. Future storage-strategy changes fail
      # this spec instead of silently wedging replication at IAM boundary.
      it 'sends a hashed_client_secret in the digest format IAM validates' do
        replicator.deliver(row)

        expect(client).to have_received(:upsert_oauth_application)
          .with(hash_including(hashed_client_secret: match(/\A[0-9a-f]{128}\z/)))
      end

      it 'sends an organization_id in the UUIDv7 format IAM validates' do
        replicator.deliver(row)

        expect(client).to have_received(:upsert_oauth_application).with(
          hash_including(
            organization_id: match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/)
          )
        )
      end

      it 'sends the current configured owning_cell_id' do
        replicator.deliver(row)

        expect(client).to have_received(:upsert_oauth_application).with(
          hash_including(owning_cell_id: Gitlab.config.cell.id.to_i)
        )
      end

      context 'with a different configured cell' do
        before do
          stub_config_cell(id: 7)
        end

        it 'sends the configured owning_cell_id' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(hash_including(owning_cell_id: 7))
        end
      end

      it 'delivers with a single upsert call' do
        replicator.deliver(row)

        expect(client).to have_received(:upsert_oauth_application).once
      end

      it 'returns :delivered' do
        expect(replicator.deliver(row)).to eq(:delivered)
      end

      it 'raises when the upsert fails' do
        allow(client).to receive(:upsert_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new('down', reason: :unavailable))

        expect { replicator.deliver(row) }.to raise_error(Authn::IamService::GrpcClient::RequestError)
      end

      context 'when the application is not confidential' do
        let(:application) { create(:oauth_application, confidential: false) }

        it 'omits client_credentials and marks the app public' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(
            hash_including(public: true, grant_types: %w[authorization_code refresh_token])
          )
        end
      end

      context 'when the application has no owner' do
        let(:application) { create(:oauth_application, :without_owner) }

        it 'sends the administrator label' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(hash_including(owner: 'An administrator'))
        end
      end

      context 'when the application is dynamic' do
        let(:application) { create(:oauth_application, :dynamic) }

        it 'sends no owner and marks it as dynamic' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(hash_including(owner: nil, dynamic: true))
        end
      end

      context 'when the application is owned by a group' do
        let(:application) { create(:oauth_application, :group_owned) }

        it 'sends the group name' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(hash_including(owner: application.owner.name))
        end
      end

      context 'when the application has multiple redirect URIs' do
        let(:application) do
          create(:oauth_application, redirect_uri: "https://a.example.com\nhttps://b.example.com")
        end

        it 'splits them into an array' do
          replicator.deliver(row)

          expect(client).to have_received(:upsert_oauth_application).with(
            hash_including(redirect_uris: %w[https://a.example.com https://b.example.com])
          )
        end
      end

      context 'when the Rails record is absent' do
        let(:row) { build(:iam_outbox, entity_id: non_existing_record_id) }

        it 'returns :skipped without calling IAM' do
          expect(replicator.deliver(row)).to eq(:skipped)
          expect(client).not_to have_received(:upsert_oauth_application)
        end
      end

      context 'when the secret is not a SHA-512 digest' do
        let(:application) do
          create(:oauth_application).tap { |app| app.update_column(:secret, '$pbkdf2-sha512$20000$$legacy') }
        end

        it 'returns :unsupported_secret_digest without calling IAM', :aggregate_failures do
          expect(replicator.deliver(row)).to eq(:unsupported_secret_digest)
          expect(client).not_to have_received(:upsert_oauth_application)
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

      it 'treats an already-absent client as delivered' do
        allow(client).to receive(:delete_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new('gone', reason: :not_found))

        expect(replicator.deliver(row)).to eq(:delivered)
      end

      it 'raises when the delete fails for any other reason' do
        allow(client).to receive(:delete_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new('down', reason: :unavailable))

        expect { replicator.deliver(row) }.to raise_error(Authn::IamService::GrpcClient::RequestError)
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
