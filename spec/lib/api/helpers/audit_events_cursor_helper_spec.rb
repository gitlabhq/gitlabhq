# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::AuditEventsCursorHelper, feature_category: :audit_events do
  let(:helper) { Class.new.include(described_class).new }
  let(:group) { create(:group) }
  let(:project) { create(:project) }

  describe '#enrich_audit_event_cursor' do
    let(:cursor_id) { 12345 }
    let(:created_at) { Time.zone.parse('2025-09-16 20:52:19.915156') }

    context 'when cursor is blank' do
      it 'returns the cursor unchanged' do
        expect(helper.enrich_audit_event_cursor(nil, group)).to be_nil
        expect(helper.enrich_audit_event_cursor('', group)).to eq('')
      end
    end

    context 'when cursor has no id' do
      let(:cursor) { encode_cursor({ '_kd' => 'n' }) }

      it 'returns the cursor unchanged' do
        result = helper.enrich_audit_event_cursor(cursor, group)
        expect(result).to eq(cursor)
      end
    end

    context 'when cursor already has created_at' do
      let(:cursor) do
        encode_cursor({ 'id' => cursor_id.to_s, 'created_at' => created_at.to_fs(:inspect), '_kd' => 'n' })
      end

      it 'returns the cursor unchanged' do
        result = helper.enrich_audit_event_cursor(cursor, group)
        expect(result).to eq(cursor)
      end
    end

    context 'when cursor has id but no created_at' do
      let(:cursor) { encode_cursor({ 'id' => cursor_id.to_s, '_kd' => 'n' }) }

      context 'for a group resource' do
        let!(:audit_event) do
          create(:audit_events_group_audit_event, id: cursor_id, created_at: created_at, group_id: group.id)
        end

        it 'enriches the cursor with created_at' do
          result = helper.enrich_audit_event_cursor(cursor, group)
          decoded = decode_cursor(result)

          expect(decoded['id']).to eq(cursor_id.to_s)
          expect(decoded['created_at']).to eq(created_at.to_fs(:inspect))
          expect(decoded['_kd']).to eq('n')
        end
      end

      context 'for a project resource' do
        let!(:audit_event) do
          create(:audit_events_project_audit_event, id: cursor_id, created_at: created_at, project_id: project.id)
        end

        it 'enriches the cursor with created_at' do
          result = helper.enrich_audit_event_cursor(cursor, project)
          decoded = decode_cursor(result)

          expect(decoded['id']).to eq(cursor_id.to_s)
          expect(decoded['created_at']).to eq(created_at.to_fs(:inspect))
          expect(decoded['_kd']).to eq('n')
        end
      end

      context 'when audit event does not exist' do
        it 'returns the original cursor' do
          result = helper.enrich_audit_event_cursor(cursor, group)
          expect(result).to eq(cursor)
        end
      end
    end

    context 'when cursor parsing fails' do
      let(:malformed_cursor) { 'invalid-base64' }

      it 'handles the error and returns the original cursor' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(kind_of(StandardError))
        result = helper.enrich_audit_event_cursor(malformed_cursor, group)
        expect(result).to eq(malformed_cursor)
      end
    end
  end

  describe '#strip_created_at_from_cursor' do
    context 'when cursor is blank' do
      it 'returns the cursor unchanged' do
        expect(helper.strip_created_at_from_cursor(nil)).to be_nil
        expect(helper.strip_created_at_from_cursor('')).to eq('')
      end
    end

    context 'when cursor has created_at' do
      let(:cursor) { encode_cursor({ 'id' => '12345', 'created_at' => '2025-09-16 20:52:19', '_kd' => 'n' }) }

      it 'removes created_at from the cursor' do
        result = helper.strip_created_at_from_cursor(cursor)
        decoded = decode_cursor(result)

        expect(decoded.keys).to contain_exactly('id', '_kd')
        expect(decoded['id']).to eq('12345')
        expect(decoded['_kd']).to eq('n')
      end
    end

    context 'when cursor does not have created_at' do
      let(:cursor) { encode_cursor({ 'id' => '12345', '_kd' => 'n' }) }

      it 'returns the cursor unchanged' do
        result = helper.strip_created_at_from_cursor(cursor)
        expect(result).to eq(cursor)
      end
    end

    context 'when cursor parsing fails' do
      let(:malformed_cursor) { 'invalid-base64' }

      it 'handles the error and returns the original cursor' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(kind_of(StandardError))
        result = helper.strip_created_at_from_cursor(malformed_cursor)
        expect(result).to eq(malformed_cursor)
      end
    end
  end

  def encode_cursor(data)
    Base64.urlsafe_encode64(Gitlab::Json.dump(data))
  end

  def decode_cursor(cursor)
    Gitlab::Json.parse(Base64.urlsafe_decode64(cursor)).with_indifferent_access
  end
end
