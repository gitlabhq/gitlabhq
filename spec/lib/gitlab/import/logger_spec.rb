# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Logger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.zone.now }

  describe '#format_message' do
    before do
      allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('new-correlation-id')
    end

    it 'formats strings' do
      output = subject.format_message('INFO', now, 'test', 'Hello world')

      expect(Gitlab::Json.parse(output)).to eq({
        'severity' => 'INFO',
        'time' => now.utc.iso8601(3),
        'message' => 'Hello world',
        'correlation_id' => 'new-correlation-id',
        'feature_category' => 'importers'
      })
    end

    it 'formats hashes' do
      output = subject.format_message('INFO', now, 'test', { hello: 1 })

      expect(Gitlab::Json.parse(output)).to eq({
        'severity' => 'INFO',
        'time' => now.utc.iso8601(3),
        'hello' => 1,
        'correlation_id' => 'new-correlation-id',
        'feature_category' => 'importers'
      })
    end
  end
end
