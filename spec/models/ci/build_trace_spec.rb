# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTrace, feature_category: :continuous_integration do
  let(:build) { build_stubbed(:ci_build) }
  let(:state) { nil }
  let(:data) { StringIO.new('the-stream') }

  let(:stream) do
    Gitlab::Ci::Trace::Stream.new { data }
  end

  subject { described_class.new(build: build, stream: stream, state: state) }

  describe 'delegated methods' do
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

  describe 'FF sign_and_verify_ansi2json_state' do
    before do
      stub_feature_flags(sign_and_verify_ansi2json_state: false)
    end

    it 'calls convert with verify_state: true when enabled for project' do
      build.project = create(:project)
      stub_feature_flags(sign_and_verify_ansi2json_state: build.project)

      expect(Gitlab::Ci::Ansi2json).to receive(:convert).with(stream.stream, state, verify_state: true)

      described_class.new(build: build, stream: stream, state: state)
    end

    it 'calls convert with verify_state: false when disabled' do
      expect(Gitlab::Ci::Ansi2json).to receive(:convert).with(stream.stream, state, verify_state: false)
      described_class.new(build: build, stream: stream, state: state)
    end
  end

  it 'returns formatted trace' do
    expect(subject.lines).to eq(
      [
        { offset: 0, content: [{ text: 'the-stream' }] }
      ])
  end

  context 'with invalid UTF-8 data' do
    let(:data) { StringIO.new("UTF-8 dashes here: ───\n🐤🐤🐤🐤\xF0\x9F\x90\n") }

    it 'returns valid UTF-8 data', :aggregate_failures do
      expect(subject.lines[0]).to eq({ offset: 0, content: [{ text: 'UTF-8 dashes here: ───' }] })
      # Each of the dashes is 3 bytes, so we get 19 + 9 + 1 = 29
      expect(subject.lines[1]).to eq({ offset: 29, content: [{ text: '🐤🐤🐤🐤�' }] })
    end
  end
end
