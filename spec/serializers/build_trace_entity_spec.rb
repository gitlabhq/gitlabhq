# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildTraceEntity do
  let(:build) { build_stubbed(:ci_build) }
  let(:request) { double('request') }

  let(:stream) do
    Gitlab::Ci::Trace::Stream.new do
      StringIO.new('the-trace')
    end
  end

  let(:build_trace) do
    Ci::BuildTrace.new(build: build, stream: stream, state: nil)
  end

  let(:entity) do
    described_class.new(build_trace, request: request)
  end

  subject { entity.as_json }

  it 'includes build attributes' do
    expect(subject[:id]).to eq(build.id)
    expect(subject[:status]).to eq(build.status)
    expect(subject[:complete]).to eq(build.complete?)
  end

  it 'includes trace metadata' do
    expect(subject).to include(:state)
    expect(subject).to include(:append)
    expect(subject).to include(:truncated)
    expect(subject).to include(:offset)
    expect(subject).to include(:size)
    expect(subject).to include(:total)
  end

  it 'includes the trace content in json' do
    expect(subject[:lines]).to eq(
      [
        { offset: 0, content: [{ text: 'the-trace' }] }
      ])
  end
end
