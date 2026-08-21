# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamReplication::DrainWorker, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:application) { create(:oauth_application) }

  let(:entity_type) { 'oauth_application' }

  let(:client) do
    instance_double(Authn::IamService::GrpcClient, create_oauth_application: nil, delete_oauth_application: nil)
  end

  subject(:worker) { described_class.new }

  # The feature flag is enabled by default in tests, so delete all the outbox row produced by the
  # initial `application` creation
  before do
    Authn::IamOutbox.delete_all
    allow(::Authn::IamAuthService).to receive(:enabled?).and_return(true)
    allow(Authn::IamService::GrpcClient).to receive(:new).and_return(client)
  end

  def upsert_row(entity_id: application.id)
    create(:iam_outbox, entity_type: entity_type, entity_id: entity_id, event_type: :upsert)
  end

  def delete_row(entity_id: application.id, uid: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6')
    create(:iam_outbox,
      entity_type: entity_type, entity_id: entity_id, event_type: :delete, payload: { 'uid' => uid })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [entity_type, application.id, 'upsert'] }

    before do
      upsert_row
    end

    it 'delivers once across repeated runs and marks the row delivered' do
      perform_idempotent_work

      expect(client).to have_received(:create_oauth_application).once
      expect(Authn::IamOutbox.sole.l0_delivered_at).to be_present
    end
  end

  describe '#perform' do
    context 'with an upsert event' do
      context 'when the Rails record is present' do
        it 'pushes the re-read record and marks the L0 target delivered' do
          row = upsert_row

          worker.perform(entity_type, application.id, 'upsert')

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

          expect(row.reload.l0_delivered_at).to be_present
        end

        it 'logs the delivery' do
          upsert_row

          expect(::Gitlab::AuthLogger).to receive(:info).with(
            hash_including(
              'entity_type' => entity_type,
              'entity_id' => application.id,
              'event_type' => 'upsert',
              'target' => described_class::TARGET,
              'attempts' => 0,
              'result' => :delivered
            )
          )

          worker.perform(entity_type, application.id, 'upsert')
        end

        it 'replaces the upstream client', :aggregate_failures do
          upsert_row

          worker.perform(entity_type, application.id, 'upsert')

          expect(client).to have_received(:delete_oauth_application).with(client_id: application.uid).ordered
          expect(client).to have_received(:create_oauth_application).ordered
        end

        it 'treats a missing upstream client as a first create rather than a failure' do
          upsert_row
          allow(client).to receive(:delete_oauth_application)
            .and_raise(Authn::IamService::GrpcClient::RequestError.new('gone', reason: :not_found))

          expect { worker.perform(entity_type, application.id, 'upsert') }.not_to raise_error

          expect(client).to have_received(:create_oauth_application)
        end

        it 'fails when the replace delete fails for any other reason' do
          upsert_row
          allow(client).to receive(:delete_oauth_application)
            .and_raise(Authn::IamService::GrpcClient::RequestError.new('down', reason: :unavailable))

          expect { worker.perform(entity_type, application.id, 'upsert') }
            .to raise_error(Authn::IamService::GrpcClient::RequestError)

          expect(client).not_to have_received(:create_oauth_application)
        end

        where(:confidential, :trusted, :expected_public, :expected_grant_types) do
          true  | false | false | %w[authorization_code refresh_token client_credentials]
          false | false | true  | %w[authorization_code refresh_token]
          true  | true  | false | %w[authorization_code refresh_token client_credentials]
        end

        with_them do
          it 'sends the confidentiality, trust, and grant types the client is entitled to' do
            app = create(:oauth_application, confidential: confidential, trusted: trusted)
            create(:iam_outbox, entity_type: entity_type, entity_id: app.id, event_type: :upsert)

            worker.perform(entity_type, app.id, 'upsert')

            expect(client).to have_received(:create_oauth_application).with(
              hash_including(
                public: expected_public,
                trusted: trusted,
                grant_types: expected_grant_types
              )
            )
          end
        end
      end

      context 'when the Rails record is absent' do
        it 'skips the creation but marks the row delivered' do
          row = upsert_row(entity_id: non_existing_record_id)
          expect(client).not_to receive(:create_oauth_application)

          worker.perform(entity_type, non_existing_record_id, 'upsert')

          expect(row.reload.l0_delivered_at).to be_present
        end

        it 'logs the skipped delivery' do
          upsert_row(entity_id: non_existing_record_id)

          expect(::Gitlab::AuthLogger).to receive(:info).with(hash_including('result' => :skipped))

          worker.perform(entity_type, non_existing_record_id, 'upsert')
        end
      end
    end

    context 'when reporting the owner' do
      where(:factory_trait, :expected_owner) do
        :without_owner | 'An administrator'
        :dynamic       | 'An anonymous service'
        :group_owned   | :owner_name
      end

      with_them do
        it 'reports a name IAM can render on the consent screen' do
          app = create(:oauth_application, factory_trait)
          create(:iam_outbox, entity_type: entity_type, entity_id: app.id, event_type: :upsert)
          owner = expected_owner == :owner_name ? app.owner.name : expected_owner

          worker.perform(entity_type, app.id, 'upsert')

          expect(client).to have_received(:create_oauth_application).with(hash_including(owner: owner))
        end
      end
    end

    context 'with a delete event' do
      it 'removes via the payload uid and marks L0 delivered' do
        row = delete_row

        worker.perform(entity_type, application.id, 'delete')

        expect(client).to have_received(:delete_oauth_application)
          .with(client_id: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6')
        expect(row.reload.l0_delivered_at).to be_present
      end
    end

    context 'when the gRPC client raises error' do
      before do
        allow(client).to receive(:create_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new(
            'IAM auth service is not configured', reason: :unavailable))
      end

      it 'records the gRPC reason, leaves the target undelivered, and re-raises for retry',
        :aggregate_failures do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError, 'IAM auth service is not configured')

        row.reload
        expect(row.l0_attempts).to eq(1)
        expect(row.l0_last_error).to eq('unavailable')
        expect(row.l0_delivered_at).to be_nil
      end

      it 'logs the failure with the incremented attempt count' do
        upsert_row

        expect(::Gitlab::AuthLogger).to receive(:info)
          .with(hash_including('result' => :error, 'attempts' => 1))

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError)
      end
    end

    context 'when the gRPC client raises something other than a RequestError' do
      before do
        allow(client).to receive(:create_oauth_application).and_raise(ArgumentError)
      end

      it 'falls back to the class name, since only a RequestError carries a reason', :aggregate_failures do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'upsert') }.to raise_error(ArgumentError)

        row.reload
        expect(row.l0_attempts).to eq(1)
        expect(row.l0_last_error).to eq('ArgumentError')
        expect(row.l0_delivered_at).to be_nil
      end
    end

    context 'with an unknown event_type' do
      it 'raises and leaves the row undelivered' do
        row = upsert_row

        expect { worker.perform(entity_type, application.id, 'unknown') }
          .to raise_error(ArgumentError, /unknown event_type/)

        expect(row.reload.l0_delivered_at).to be_nil
      end
    end

    context 'with several undelivered rows for the same entity' do
      before do
        3.times { upsert_row }
      end

      it 'collapses them into a single delivery and marks them all delivered', :aggregate_failures do
        worker.perform(entity_type, application.id, 'upsert')

        expect(client).to have_received(:create_oauth_application).once
        expect(Authn::IamOutbox.l0_undelivered).to be_empty
      end

      it 'leaves every row undelivered for retry when delivery fails', :aggregate_failures do
        allow(client).to receive(:create_oauth_application)
          .and_raise(Authn::IamService::GrpcClient::RequestError.new(
            'IAM auth service is not configured', reason: :unavailable))

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .to raise_error(Authn::IamService::GrpcClient::RequestError)

        expect(Authn::IamOutbox.l0_undelivered.count).to eq(3)
        expect(Authn::IamOutbox.pluck(:l0_attempts)).to all(eq(1))
      end

      # Relies on find_by_id running after the ids are pinned, so the row inserted here is not in
      # the id_in set the drain marks delivered.
      it 'leaves a row written after the delivery read pending for its own drain' do
        allow(::Authn::OauthApplication).to receive(:find_by_id).and_wrap_original do |method, id|
          upsert_row
          method.call(id)
        end

        worker.perform(entity_type, application.id, 'upsert')

        expect(Authn::IamOutbox.l0_undelivered.count).to eq(1)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(iam_data_replication: false)
      end

      it 'is a no-op and never builds a client' do
        row = upsert_row
        expect(Authn::IamService::GrpcClient).not_to receive(:new)

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .not_to change { row.reload.l0_delivered_at }
      end
    end

    context 'when the IAM auth service is disabled' do
      before do
        allow(::Authn::IamAuthService).to receive(:enabled?).and_return(false)
      end

      it 'is a no-op and never builds a client' do
        row = upsert_row
        expect(Authn::IamService::GrpcClient).not_to receive(:new)

        expect { worker.perform(entity_type, application.id, 'upsert') }
          .not_to change { row.reload.l0_delivered_at }
      end
    end
  end
end
