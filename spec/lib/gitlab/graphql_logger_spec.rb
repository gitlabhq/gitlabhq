# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GraphqlLogger do
  subject { described_class.new('/dev/null') }
  let(:now) { Time.now }

  it 'builds a logger once' do
    expect(::Logger).to receive(:new).and_call_original

    subject.info('hello world')
    subject.error('hello again')
  end
end
