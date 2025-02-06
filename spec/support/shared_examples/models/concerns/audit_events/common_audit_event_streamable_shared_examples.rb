# frozen_string_literal: true

RSpec.shared_examples 'streaming audit event model' do
  let_it_be(:audit_event) { create(:"audit_events_#{described_class.name.demodulize.underscore}") }

  describe '#stream_to_external_destinations' do
    let(:event_name) { 'custom_event' }
    let(:streamer) { instance_double(AuditEvents::ExternalDestinationStreamer) }

    before do
      stub_feature_flags(stream_audit_events_from_new_tables: true)
      allow(AuditEvents::ExternalDestinationStreamer)
        .to receive(:new)
        .with(event_name, audit_event)
        .and_return(streamer)
      allow(streamer).to receive(:streamable?).and_return(true)
    end

    it 'enqueues a streaming worker' do
      expect(AuditEvents::AuditEventStreamingWorker)
        .to receive(:perform_async)
        .with('custom_event', nil, kind_of(String))

      audit_event.stream_to_external_destinations(event_name: event_name, use_json: true)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(stream_audit_events_from_new_tables: false)
      end

      it 'does not enqueue worker' do
        expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)

        audit_event.stream_to_external_destinations(event_name: event_name)
      end
    end

    context 'when not streamable' do
      before do
        allow(streamer).to receive(:streamable?).and_return(false)
      end

      it 'does not enqueue worker' do
        expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)

        audit_event.stream_to_external_destinations(event_name: event_name)
      end
    end
  end

  describe '#entity_is_group_or_project?' do
    it 'returns the expected result' do
      expected = described_class.name.include?('Group') || described_class.name.include?('Project')
      expect(audit_event.entity_is_group_or_project?).to eq(expected)
    end
  end
end
