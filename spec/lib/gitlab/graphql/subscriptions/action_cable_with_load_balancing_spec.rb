# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Subscriptions::ActionCableWithLoadBalancing, feature_category: :shared do
  let(:field) { Types::SubscriptionType.fields.each_value.first }
  let(:event) { ::GraphQL::Subscriptions::Event.new(name: 'test-event', arguments: {}, field: field) }
  let(:object) { build(:project, id: 1) }
  let(:action_cable) { instance_double(::ActionCable::Server::Broadcasting) }

  subject(:subscriptions) { described_class.new(schema: GitlabSchema) }

  include_context 'when tracking WAL location reference'

  before do
    allow(::ActionCable).to receive(:server).and_return(action_cable)
    allow(::Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('abc-123')
  end

  context 'when triggering subscription' do
    shared_examples_for 'injecting WAL locations' do
      it 'injects correct WAL location into message' do
        expect(action_cable).to receive(:broadcast) do |topic, payload|
          expect(topic).to match(/^graphql-event/)
          expect(Gitlab::Json.parse(payload)).to match({
            described_class::KEY_WAL_LOCATIONS => expected_locations,
            described_class::KEY_CORRELATION_ID => 'abc-123',
            described_class::KEY_PAYLOAD => { '__gid__' => 'Z2lkOi8vZ2l0bGFiL1Byb2plY3QvMQ' }
          })
        end

        subscriptions.execute_all(event, object)
      end
    end

    context 'when database load balancing is disabled' do
      let!(:expected_locations) { {} }

      before do
        stub_load_balancing_disabled!
      end

      it_behaves_like 'injecting WAL locations'
    end

    context 'when database load balancing is enabled' do
      before do
        stub_load_balancing_enabled!
      end

      context 'when write was not performed' do
        before do
          stub_no_writes_performed!
        end

        context 'when replica hosts are available' do
          let!(:expected_locations) { expect_tracked_locations_when_replicas_available.with_indifferent_access }

          it_behaves_like 'injecting WAL locations'
        end

        context 'when no replica hosts are available' do
          let!(:expected_locations) { expect_tracked_locations_when_no_replicas_available.with_indifferent_access }

          it_behaves_like 'injecting WAL locations'
        end
      end

      context 'when write was performed' do
        let!(:expected_locations) { expect_tracked_locations_from_primary_only.with_indifferent_access }

        before do
          stub_write_performed!
        end

        it_behaves_like 'injecting WAL locations'
      end
    end
  end

  context 'when receiving a broadcast' do
    let_it_be(:broadcast_project) { create(:project) }

    let(:serialized_project) { { '__gid__' => Base64.urlsafe_encode64(broadcast_project.to_gid.to_s, padding: false) } }

    let(:raw_message) do
      Gitlab::Json.dump({
        described_class::KEY_WAL_LOCATIONS => wal_locations,
        described_class::KEY_CORRELATION_ID => 'abc-123',
        described_class::KEY_PAYLOAD => serialized_project
      })
    end

    let(:wal_locations) { { 'main' => current_location } }

    before do
      stub_feature_flags(graphql_subscription_primary_fallback_on_load: true)
    end

    def primary_pinned?
      Gitlab::Database::LoadBalancing::SessionMap
        .current(ApplicationRecord.load_balancer)
        .use_primary?
    end

    def load_message!
      subscriptions.load_action_cable_message(raw_message, nil)
    end

    # Instantiating the transport reflects on Serialize.load's arity, so it has to exist
    # before the spy below replaces that method.
    def spy_on_payload_resolution!
      subscriptions

      pinned = { during_lookup: nil }

      allow(::GraphQL::Subscriptions::Serialize).to receive(:load).and_wrap_original do |original, *args|
        pinned[:during_lookup] = primary_pinned?
        original.call(*args)
      end

      pinned
    end

    context 'when database replicas are not in sync' do
      before do
        stub_replica_available!(false)
      end

      it 'pins to the primary before the payload is resolved' do
        pinned = spy_on_payload_resolution!

        expect(load_message!).to match(
          described_class::KEY_PAYLOAD => broadcast_project,
          described_class::KEY_WAL_LOCATIONS => wal_locations,
          described_class::KEY_CORRELATION_ID => 'abc-123'
        )
        expect(pinned[:during_lookup]).to be(true)
      end
    end

    context 'when database replicas are in sync' do
      before do
        stub_replica_available!(true)
      end

      it 'does not pin to the primary' do
        pinned = spy_on_payload_resolution!

        expect(load_message!).to match(
          described_class::KEY_PAYLOAD => broadcast_project,
          described_class::KEY_WAL_LOCATIONS => wal_locations,
          described_class::KEY_CORRELATION_ID => 'abc-123'
        )
        expect(pinned[:during_lookup]).to be(false)
      end
    end

    context 'when WAL locations are absent' do
      let(:wal_locations) { {} }

      it 'pins to the primary' do
        pinned = spy_on_payload_resolution!

        load_message!

        expect(pinned[:during_lookup]).to be(true)
      end
    end

    context 'when the envelope cannot be parsed' do
      before do
        stub_replica_available!(true)
      end

      context 'when it exceeds the safe parser limits but is valid JSON' do
        before do
          stub_const('Gitlab::Json::PARSE_LIMITS', Gitlab::Json::PARSE_LIMITS.merge(max_json_size_bytes: 1))
        end

        it 'pins to the primary and still resolves the payload' do
          pinned = spy_on_payload_resolution!

          expect(load_message!).to match(
            described_class::KEY_PAYLOAD => broadcast_project,
            described_class::KEY_WAL_LOCATIONS => wal_locations,
            described_class::KEY_CORRELATION_ID => 'abc-123'
          )
          expect(pinned[:during_lookup]).to be(true)
        end
      end

      context 'when it is malformed' do
        let(:raw_message) { '{"wal_locations":' }

        it 'pins to the primary and leaves the failure to the serializer' do
          expect { load_message! }.to raise_error(::JSON::ParserError)

          expect(primary_pinned?).to be(true)
        end
      end
    end

    context 'when it logs the fallback' do
      def expect_fallback_logged(reason)
        expect(Gitlab::Database::LoadBalancing::Logger).to receive(:info).with(
          event: :graphql_subscription_primary_fallback,
          fallback_reason: reason,
          ::Labkit::Fields::CORRELATION_ID => 'abc-123'
        )
      end

      it 'records the originating correlation id and that the replicas were behind' do
        stub_replica_available!(false)
        expect_fallback_logged(:replicas_behind)

        load_message!
      end

      context 'when WAL locations are absent' do
        let(:wal_locations) { {} }

        it 'says so' do
          expect_fallback_logged(:wal_locations_absent)

          load_message!
        end
      end

      context 'when the envelope cannot be read' do
        let(:raw_message) { '{"wal_locations":' }

        it 'says so and has no correlation id to record' do
          expect(Gitlab::Database::LoadBalancing::Logger).to receive(:info).with(
            event: :graphql_subscription_primary_fallback,
            fallback_reason: :envelope_unreadable,
            ::Labkit::Fields::CORRELATION_ID => nil
          )

          expect { load_message! }.to raise_error(::JSON::ParserError)
        end
      end

      it 'logs nothing when the replicas are in sync' do
        stub_replica_available!(true)

        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)

        load_message!
      end
    end

    context 'when the message is not a wrapped envelope' do
      let(:raw_message) { Gitlab::Json.dump(serialized_project) }

      it 'makes no routing decision and passes the payload through' do
        expect(Gitlab::Database::LoadBalancing::SessionMap).not_to receive(:with_sessions)

        expect(load_message!).to eq(broadcast_project)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(graphql_subscription_primary_fallback_on_load: false)
        stub_replica_available!(false)
      end

      it 'leaves the routing decision to execute_update' do
        pinned = spy_on_payload_resolution!

        load_message!

        expect(pinned[:during_lookup]).to be(false)
      end
    end
  end

  context 'when handling event' do
    def handle_event!(wal_locations: nil)
      subscriptions.execute_update('sub:123', event, {
        described_class::KEY_WAL_LOCATIONS => wal_locations || {
          'main' => current_location
        },
        described_class::KEY_PAYLOAD => { '__gid__' => 'Z2lkOi8vZ2l0bGFiL1Byb2plY3QvMQ' }
      })
    end

    before do
      allow(action_cable).to receive(:broadcast)
      stub_feature_flags(graphql_subscription_primary_fallback_on_load: false)
    end

    context 'when database replicas are not in sync' do
      it 'uses the primary' do
        stub_replica_available!(false)

        expect(Gitlab::Database::LoadBalancing::SessionMap)
          .to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models).and_call_original

        expect_next_instance_of(Gitlab::Database::LoadBalancing::ScopedSessions) do |inst|
          expect(inst).to receive(:use_primary!).and_call_original
        end

        handle_event!
      end
    end

    context 'when database replicas are in sync' do
      it 'does not use the primary' do
        stub_replica_available!(true)

        expect(Gitlab::Database::LoadBalancing::SessionMap)
          .not_to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models)

        handle_event!
      end
    end

    context 'when WAL locations are not present' do
      it 'uses the primary' do
        expect_next_instance_of(Gitlab::Database::LoadBalancing::ScopedSessions) do |inst|
          expect(inst).to receive(:use_primary!).and_call_original
        end

        handle_event!(wal_locations: {})
      end
    end

    context 'when event payload is not wrapped' do
      it 'does not attempt to unwrap it' do
        expect(object).not_to receive(:[]).with(described_class::KEY_PAYLOAD)

        subscriptions.execute_update('sub:123', event, object)
      end
    end

    it 'strips out WAL location information before broadcasting payload' do
      expect(action_cable).to receive(:broadcast) do |topic, payload|
        expect(topic).to eq('graphql-subscription:sub:123')
        expect(payload).to eq({ more: false })
      end

      handle_event!
    end
  end
end
