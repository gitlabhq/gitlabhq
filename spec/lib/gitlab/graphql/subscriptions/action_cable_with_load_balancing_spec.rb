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
  end

  context 'when triggering subscription' do
    shared_examples_for 'injecting WAL locations' do
      it 'injects correct WAL location into message' do
        expect(action_cable).to receive(:broadcast) do |topic, payload|
          expect(topic).to match(/^graphql-event/)
          expect(Gitlab::Json.parse(payload)).to match({
            described_class::KEY_WAL_LOCATIONS => expected_locations,
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
    end

    context 'when event payload is not wrapped' do
      it 'does not attempt to unwrap it' do
        expect(object).not_to receive(:[]).with(described_class::KEY_PAYLOAD)

        subscriptions.execute_update('sub:123', event, object)
      end
    end

    context 'when WAL locations are not present' do
      it 'uses the primary' do
        expect(Gitlab::Database::LoadBalancing::SessionMap)
          .to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models).and_call_original

        expect_next_instance_of(Gitlab::Database::LoadBalancing::ScopedSessions) do |inst|
          expect(inst).to receive(:use_primary!).and_call_original
        end

        handle_event!(wal_locations: {})
      end
    end

    it 'strips out WAL location information before broadcasting payload' do
      expect(action_cable).to receive(:broadcast) do |topic, payload|
        expect(topic).to eq('graphql-subscription:sub:123')
        expect(payload).to eq({ more: false })
      end

      handle_event!
    end

    context 'when database replicas are in sync' do
      it 'does not use the primary' do
        stub_replica_available!(true)

        expect(Gitlab::Database::LoadBalancing::SessionMap)
          .not_to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models).and_call_original

        handle_event!
      end
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
  end
end
