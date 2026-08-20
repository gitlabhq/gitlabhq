# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Logging, feature_category: :audit_events do
  let(:test_class) do
    Class.new do
      include Gitlab::Audit::Logging
    end
  end

  let(:instance) { test_class.new }
  let_it_be(:author) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  describe '#persist_events' do
    def build_group_event(event_name)
      AuditEvents::GroupAuditEvent.new(
        author_id: author.id,
        group_id: group.id,
        event_name: event_name,
        created_at: Time.current,
        details: { event_name: event_name, custom_message: event_name }
      )
    end

    context 'with a single event' do
      let(:event) { build_group_event('test_event') }

      it 'saves the event and returns it' do
        expect { instance.persist_events([event], 'test_operation') }
          .to change { AuditEvents::GroupAuditEvent.count }.by(1)

        expect(event).to be_persisted
      end

      it 'returns the same instance so callers see the generated id' do
        result = instance.persist_events([event], 'test_operation')

        expect(result).to contain_exactly(event)
        expect(result.first.id).to be_present
      end
    end

    context 'with multiple events of the same scope' do
      let(:events) { [build_group_event('test_event'), build_group_event('test_event_2')] }

      it 'bulk inserts them and returns the persisted records' do
        expect(AuditEvents::GroupAuditEvent).to receive(:bulk_insert!).with(events, returns: :ids).and_call_original

        result = instance.persist_events(events, 'test_operation')

        expect(result.map(&:event_name)).to contain_exactly('test_event', 'test_event_2')
      end
    end

    context 'with events across several scopes' do
      let(:project_event) do
        AuditEvents::ProjectAuditEvent.new(
          author_id: author.id,
          project_id: project.id,
          event_name: 'project_event',
          created_at: Time.current,
          details: { event_name: 'project_event', custom_message: 'project_event' }
        )
      end

      let(:events) { [build_group_event('test_event'), build_group_event('test_event_2'), project_event] }

      it 'groups by model so each scoped table is written separately' do
        expect(AuditEvents::GroupAuditEvent).to receive(:bulk_insert!).and_call_original
        expect(AuditEvents::ProjectAuditEvent).not_to receive(:bulk_insert!)

        expect { instance.persist_events(events, 'test_operation') }
          .to change { AuditEvents::GroupAuditEvent.count }.by(2)
          .and change { AuditEvents::ProjectAuditEvent.count }.by(1)
      end
    end

    context 'when events are blank' do
      it 'returns an empty array without touching the database' do
        expect(AuditEvents::GroupAuditEvent).not_to receive(:bulk_insert!)

        expect(instance.persist_events([], 'test_operation')).to eq([])
      end
    end

    context 'when an event is invalid' do
      let(:event) { build_group_event('test_event').tap { |e| e.author_id = nil } }

      it 'tracks the exception and returns an empty array' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(ActiveRecord::RecordInvalid), audit_operation: 'test_operation')

        expect(instance.persist_events([event], 'test_operation')).to eq([])
      end
    end
  end

  describe '#log_to_new_tables' do
    let(:audit_event) do
      build(:audit_event,
        author_id: author.id,
        entity_id: group.id,
        entity_type: 'Group',
        created_at: Time.current,
        details: { event_name: 'test_event' }
      )
    end

    context 'when event has an id (legacy writes enabled)' do
      before do
        audit_event.id = 12345
      end

      it 'reuses the legacy id in the scoped table' do
        result = instance.log_to_new_tables([audit_event], 'test_operation')

        expect(result.first).to be_a(AuditEvents::GroupAuditEvent)
        expect(result.first.id).to eq(12345)
      end
    end

    context 'when event does not have an id (legacy write failed)' do
      before do
        audit_event.id = nil
      end

      it 'falls back to the scoped table sequence' do
        result = instance.log_to_new_tables([audit_event], 'test_operation')

        expect(result.first).to be_a(AuditEvents::GroupAuditEvent)
        expect(result.first.id).to be_present
      end
    end

    context 'with bulk insert (multiple events)' do
      let(:audit_event2) do
        build(:audit_event,
          author_id: author.id,
          entity_id: group.id,
          entity_type: 'Group',
          details: { event_name: 'test_event_2' },
          created_at: Time.current
        )
      end

      before do
        audit_event.id = 12345
        audit_event2.id = 12346
      end

      it 'passes the provided ids to bulk_insert!' do
        result = instance.log_to_new_tables([audit_event, audit_event2], 'test_operation')

        expect(result.map(&:id)).to contain_exactly(12345, 12346)
      end
    end
  end

  describe '#build_event_attributes' do
    let(:audit_event) do
      build(:audit_event,
        author_id: author.id,
        entity_id: group.id,
        entity_type: 'Group',
        details: { event_name: 'test_event' }
      )
    end

    context 'when event has an id' do
      before do
        audit_event.id = 12345
      end

      it 'includes the id in attributes' do
        attributes = instance.send(:build_event_attributes, audit_event)

        expect(attributes[:id]).to eq(12345)
      end
    end

    context 'when event does not have an id' do
      before do
        audit_event.id = nil
      end

      it 'does not include the id in attributes' do
        attributes = instance.send(:build_event_attributes, audit_event)

        expect(attributes).not_to have_key(:id)
      end
    end

    it 'maps the legacy entity to the scoped foreign key' do
      attributes = instance.send(:build_event_attributes, audit_event)

      expect(attributes).to include(group_id: group.id)
    end
  end
end
