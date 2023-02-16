# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JsonLogger do
  subject { described_class.new('/dev/null') }

  let(:now) { Time.now }

  describe '#file_name' do
    let(:subclass) do
      Class.new(Gitlab::JsonLogger) do
        def self.file_name_noext
          'testlogger'
        end
      end
    end

    it 'raises error when file_name_noext not implemented' do
      expect { described_class.file_name }.to raise_error(
        'JsonLogger implementations must provide file_name_noext implementation'
      )
    end

    it 'returns log file name when file_name_noext is implemented' do
      expect(subclass.file_name).to eq('testlogger.log')
    end
  end

  describe '#format_message' do
    it 'formats strings' do
      output = subject.format_message('INFO', now, 'test', 'Hello world')
      data = Gitlab::Json.parse(output)

      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['message']).to eq('Hello world')
      expect(data['correlation_id']).to be_an_instance_of(String)
    end

    it 'formats hashes' do
      output = subject.format_message('INFO', now, 'test', { hello: 1 })
      data = Gitlab::Json.parse(output)

      expect(data['severity']).to eq('INFO')
      expect(data['time']).to eq(now.utc.iso8601(3))
      expect(data['hello']).to eq(1)
      expect(data['message']).to be_nil
      expect(data['correlation_id']).to be_an_instance_of(String)
    end
  end
end
