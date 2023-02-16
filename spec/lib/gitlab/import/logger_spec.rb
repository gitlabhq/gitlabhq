# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Logger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.zone.now }

  describe '#format_message' do
    it 'formats strings' do
      output = subject.format_message('INFO', now, 'test', 'Hello world')

      expect(Gitlab::Json.parse(output)).to include({
        'severity' => 'INFO',
        'time' => now.utc.iso8601(3),
        'message' => 'Hello world',
        'correlation_id' => an_instance_of(String),
        'feature_category' => 'importers'
      })
    end

    it 'formats hashes' do
      output = subject.format_message('INFO', now, 'test', { hello: 1 })

      expect(Gitlab::Json.parse(output)).to include({
        'severity' => 'INFO',
        'time' => now.utc.iso8601(3),
        'hello' => 1,
        'correlation_id' => an_instance_of(String),
        'feature_category' => 'importers'
      })
    end
  end
end
