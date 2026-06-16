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

  describe '#log_to_new_tables' do
    let(:audit_event) do
      build(:audit_event,
        author_id: author.id,
        entity_id: group.id,
        entity_type: 'Group',
        details: { event_name: 'test_event' }
      )
    end

    # Stub database operations to avoid partition issues in test environment
    let(:mock_group_audit_event) { build_stubbed(:audit_events_group_audit_event, group_id: group.id) }

    context 'when event has an id (legacy writes enabled)' do
      before do
        audit_event.id = 12345
      end

      it 'passes the provided id to create!' do
        expect(AuditEvents::GroupAuditEvent).to receive(:create!) do |attrs|
          expect(attrs[:id]).to eq(12345)
          mock_group_audit_event
        end

        instance.log_to_new_tables([audit_event], 'test_operation')
      end
    end

    context 'when event does not have an id (legacy writes skipped)' do
      before do
        audit_event.id = nil
      end

      it 'does not pass id to create! (uses auto-generated id)' do
        expect(AuditEvents::GroupAuditEvent).to receive(:create!) do |attrs|
          expect(attrs).not_to have_key(:id)
          mock_group_audit_event
        end

        instance.log_to_new_tables([audit_event], 'test_operation')
      end

      it 'calls create! on the correct scoped table class' do
        expect(AuditEvents::GroupAuditEvent).to receive(:create!).and_return(mock_group_audit_event)

        instance.log_to_new_tables([audit_event], 'test_operation')
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
        audit_event.created_at = Time.current
      end

      context 'when events have ids' do
        before do
          audit_event.id = 12345
          audit_event2.id = 12346
        end

        it 'passes the provided ids to bulk_insert!' do
          expect(AuditEvents::GroupAuditEvent).to receive(:bulk_insert!) do |events, **_opts|
            ids = events.map { |e| e.attributes['id'] || e.id }
            expect(ids).to contain_exactly(12345, 12346)
            [12345, 12346]
          end
          allow(AuditEvents::GroupAuditEvent).to receive(:id_in)
            .and_return([mock_group_audit_event, mock_group_audit_event])

          instance.log_to_new_tables([audit_event, audit_event2], 'test_operation')
        end
      end

      context 'when events do not have ids' do
        before do
          audit_event.id = nil
          audit_event2.id = nil
        end

        it 'does not pass ids to bulk_insert! (uses auto-generated ids)' do
          expect(AuditEvents::GroupAuditEvent).to receive(:bulk_insert!) do |events, **_opts|
            events.each do |event|
              # When id is nil, the attribute value should be nil (not set to a specific value)
              expect(event.id).to be_nil
            end
            [1, 2]
          end
          allow(AuditEvents::GroupAuditEvent).to receive(:id_in)
            .and_return([mock_group_audit_event, mock_group_audit_event])

          instance.log_to_new_tables([audit_event, audit_event2], 'test_operation')
        end
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
  end
end
