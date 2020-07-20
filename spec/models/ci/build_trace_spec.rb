# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTrace do
  let(:build) { build_stubbed(:ci_build) }
  let(:state) { nil }
  let(:data) { StringIO.new('the-stream') }

  let(:stream) do
    Gitlab::Ci::Trace::Stream.new { data }
  end

  subject { described_class.new(build: build, stream: stream, state: state) }

  shared_examples 'delegates methods' do
    it { is_expected.to delegate_method(:state).to(:trace) }
    it { is_expected.to delegate_method(:append).to(:trace) }
    it { is_expected.to delegate_method(:truncated).to(:trace) }
    it { is_expected.to delegate_method(:offset).to(:trace) }
    it { is_expected.to delegate_method(:size).to(:trace) }
    it { is_expected.to delegate_method(:total).to(:trace) }
    it { is_expected.to delegate_method(:id).to(:build).with_prefix }
    it { is_expected.to delegate_method(:status).to(:build).with_prefix }
    it { is_expected.to delegate_method(:complete?).to(:build).with_prefix }
  end

  it_behaves_like 'delegates methods'

  it 'returns formatted trace' do
    expect(subject.lines).to eq([
      { offset: 0, content: [{ text: 'the-stream' }] }
    ])
  end
end
