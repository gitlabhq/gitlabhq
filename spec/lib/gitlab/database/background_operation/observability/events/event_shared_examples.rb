# frozen_string_literal: true

RSpec.shared_examples 'logging the correct payload' do
  subject(:event) { described_class.new(record, **attributes) }

  it { expect(event.payload).to(include(expected_payload)) }

  describe '#log' do
    it 'logs the transition event to app logger' do
      expect(Gitlab::AppLogger).to receive(:info).with(hash_including(expected_payload))
      event.log
    end
  end
end
