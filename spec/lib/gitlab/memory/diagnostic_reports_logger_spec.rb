# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Memory::DiagnosticReportsLogger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.current }

  describe '#format_message' do
    it 'formats incoming hash properly' do
      output = subject.format_message('INFO', now, 'test', { hello: 1 })
      # Disabling the cop because it is not relevant, we encode with `JSON.generate`. Allows `fast_spec_helper`.
      data = JSON.parse(output) # rubocop: disable Gitlab/Json

      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['hello']).to eq(1)
      expect(data['message']).to be_nil
    end
  end
end
