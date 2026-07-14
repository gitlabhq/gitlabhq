# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BillingEvents::Client, :freeze_time, feature_category: :application_instrumentation do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  let(:event_type) { 'secrets_read' }
  let(:category) { 'Gitlab::SecretManager::AuditCallback' }
  let(:unit_of_measure) { 'request' }
  let(:quantity) { 1 }
  let(:metadata) { { mount_path: '/secrets/group-123' } }

  let(:required_args) do
    {
      event_type: event_type,
      category: category,
      unit_of_measure: unit_of_measure,
      quantity: quantity,
      namespace: namespace
    }
  end

  before do
    allow(Gitlab::Tracking).to receive(:billing_event)
  end

  describe '.track_billing_event' do
    it 'delegates to an instance' do
      expect_next_instance_of(described_class) do |client|
        expect(client).to receive(:track_billing_event).with(**required_args)
      end

      described_class.track_billing_event(**required_args)
    end
  end

  describe '#track_billing_event' do
    subject(:track) { described_class.new.track_billing_event(**args) }

    let(:args) { required_args }

    it 'sends a billing event via Gitlab::Tracking.billing_event' do
      track

      expect(Gitlab::Tracking).to have_received(:billing_event).with(
        category,
        event_type,
        context: [an_instance_of(SnowplowTracker::SelfDescribingJson)]
      )
    end

    it 'fires a usage_billing_event internal event for correlation' do
      allow(SecureRandom).to receive(:uuid).and_return('correlated-uuid')

      expect { track }
        .to trigger_internal_events('usage_billing_event')
        .with(
          category: category,
          user: nil,
          namespace: namespace,
          project: nil,
          additional_properties: {
            label: 'correlated-uuid',
            property: event_type
          }
        )
    end

    context 'with user and project' do
      let(:args) { required_args.merge(user: user, project: project) }

      it 'passes user and project to the internal event' do
        expect { track }
          .to trigger_internal_events('usage_billing_event')
          .with(
            category: category,
            user: user,
            namespace: namespace,
            project: project,
            additional_properties: {
              label: an_instance_of(String),
              property: event_type
            }
          )
      end
    end

    it 'builds a billing context with the correct schema and fields' do
      track

      expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
        data = context.first.to_json[:data]
        expect(data).to include(
          event_type: event_type,
          unit_of_measure: unit_of_measure,
          quantity: quantity,
          timestamp: Time.current.iso8601
        )
      end
    end

    it 'generates a random UUID event_id when no idempotency_key is given' do
      allow(SecureRandom).to receive(:uuid).and_return('test-uuid-1234')

      track

      expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
        data = context.first.to_json[:data]
        expect(data[:event_id]).to eq('test-uuid-1234')
      end
    end

    context 'with idempotency_key' do
      let(:args) { required_args.merge(idempotency_key: 'secrets_read:req-abc-123') }

      it 'generates a deterministic event_id from the key', :aggregate_failures do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expected_id = Digest::UUID.uuid_v5(
            Gitlab::GlobalAnonymousId.instance_uuid,
            'secrets_read:req-abc-123'
          )
          expect(data[:event_id]).to eq(expected_id)
        end
      end

      it 'produces the same event_id on retry' do
        2.times { described_class.new.track_billing_event(**args) }

        event_ids = []
        expect(Gitlab::Tracking).to have_received(:billing_event).twice do |_cat, _action, context:|
          event_ids << context.first.to_json[:data][:event_id]
        end
        expect(event_ids.uniq.size).to eq(1)
      end
    end

    context 'with custom timestamp' do
      let(:custom_time) { Time.utc(2026, 6, 15, 0, 0, 0) }
      let(:args) { required_args.merge(timestamp: custom_time) }

      it 'uses the provided timestamp instead of Time.current' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data[:timestamp]).to eq(custom_time.iso8601)
        end
      end
    end

    context 'without custom timestamp' do
      it 'defaults to Time.current' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data[:timestamp]).to eq(Time.current.iso8601)
        end
      end
    end

    context 'with namespace' do
      it 'includes namespace_id and root_namespace_id' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data).to include(
            namespace_id: namespace.id,
            root_namespace_id: namespace.root_ancestor.id
          )
        end
      end
    end

    context 'with project' do
      let(:args) { required_args.merge(project: project) }

      it 'includes project_id' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data[:project_id]).to eq(project.id)
        end
      end
    end

    context 'with user' do
      let(:args) { required_args.merge(user: user) }

      it 'includes subject and global_user_id', :aggregate_failures do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data).to include(
            subject: user.id.to_s,
            subject_type: 'User'
          )
          expect(data[:global_user_id]).to be_present
        end
      end
    end

    context 'with metadata' do
      let(:args) { required_args.merge(metadata: metadata) }

      it 'includes metadata in the context' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data[:metadata]).to eq(metadata)
        end
      end
    end

    context 'without metadata' do
      it 'does not include metadata key in the context' do
        track

        expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
          data = context.first.to_json[:data]
          expect(data).not_to have_key(:metadata)
        end
      end
    end

    it 'includes instance-level fields', :aggregate_failures do
      track

      expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
        data = context.first.to_json[:data]
        expect(data).to include(
          instance_version: Gitlab.version_info.to_s,
          host_name: Gitlab.config.gitlab.host
        )
        expect(data[:instance_id]).to be_present
        expect(data[:unique_instance_id]).to be_present
        expect(data[:correlation_id]).to be_present
      end
    end

    context 'when billing_event_tracking feature flag is disabled' do
      before do
        stub_feature_flags(billing_event_tracking: false)
      end

      it 'does not track', :aggregate_failures do
        expect { track }.not_to trigger_internal_events('usage_billing_event')

        expect(Gitlab::Tracking).not_to have_received(:billing_event)
      end
    end

    context 'with invalid quantity' do
      where(:invalid_quantity) { [0, -1, -0.5, nil, 'string'] }

      with_them do
        let(:args) { required_args.merge(quantity: invalid_quantity) }

        it 'logs a warning and does not track', :aggregate_failures do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(message: 'BillingEvents: invalid quantity')
          )

          track

          expect(Gitlab::Tracking).not_to have_received(:billing_event)
        end
      end
    end

    context 'when Gitlab::Tracking raises an error' do
      before do
        allow(Gitlab::Tracking).to receive(:billing_event).and_raise(StandardError, 'boom')
      end

      it 'tracks the exception and does not raise', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          hash_including(event_type: event_type)
        )

        expect { track }.not_to raise_error
      end
    end

    context 'when Gitlab::InternalEvents.track_event raises an error' do
      before do
        allow(Gitlab::InternalEvents).to receive(:track_event).and_raise(StandardError, 'internal event boom')
      end

      it 'tracks the exception and does not raise', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          hash_including(event_type: event_type)
        )

        expect { track }.not_to raise_error
      end
    end

    it 'defaults realm to SM and deployment_type to self-managed', :aggregate_failures do
      track

      expect(Gitlab::Tracking).to have_received(:billing_event) do |_cat, _action, context:|
        data = context.first.to_json[:data]
        expect(data[:realm]).to eq('SM')
        expect(data[:deployment_type]).to eq('self-managed')
      end
    end
  end
end
