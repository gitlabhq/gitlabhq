# frozen_string_literal: true

RSpec.shared_examples 'tracking unique hll events' do |feature_flag|
  context 'when format is HTML' do
    let(:format) { :html }

    it 'tracks unique event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(expected_type, target_id)

      subject
    end

    it 'tracks unique event if DNT is not enabled' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(expected_type, target_id)
      request.headers['DNT'] = '0'

      subject
    end

    it 'does not track unique event if DNT is enabled' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(expected_type, target_id)
      request.headers['DNT'] = '1'

      subject
    end

    context 'when feature flag is disabled' do
      it 'does not track unique event' do
        stub_feature_flags(feature_flag => false)

        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(expected_type, target_id)

        subject
      end
    end
  end

  context 'when format is JSON' do
    let(:format) { :json }

    it 'does not track unique event if the format is JSON' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(expected_type, target_id)

      subject
    end
  end
end
