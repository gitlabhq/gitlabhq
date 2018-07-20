# coding: utf-8
require 'spec_helper'

describe Gitlab::JsonLogger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.now }

  describe '#format_message' do
    it 'formats strings' do
      output = subject.format_message('INFO', now, 'test', 'Hello world')
      data = JSON.parse(output)

      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['message']).to eq('Hello world')
    end

    it 'formats hashes' do
      output = subject.format_message('INFO', now, 'test', { hello: 1 })
      data = JSON.parse(output)

      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['hello']).to eq(1)
      expect(data['message']).to be_nil
    end
  end
end
