require 'spec_helper'

describe Gitlab::AppLogger, :request_store do
  subject { described_class }

  it 'builds a logger once' do
    expect(::Logger).to receive(:new).and_call_original

    subject.info('hello world')
    subject.error('hello again')
  end
end
