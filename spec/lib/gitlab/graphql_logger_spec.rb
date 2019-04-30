require 'spec_helper'

describe Gitlab::GraphqlLogger, :request_store do
  subject { described_class.new('/dev/null') }
  let(:now) { Time.now }

  it 'builds a logger once' do
    expect(::Logger).to receive(:new).and_call_original

    subject.info('hello world')
    subject.error('hello again')
  end

  describe '#format_message' do
    it 'formats properly' do
      output = subject.format_message('INFO', now, 'test', 'Hello world')

      expect(output).to match(/Hello world/)
    end
  end
end
