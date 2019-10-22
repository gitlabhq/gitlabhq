# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildTrace do
  let(:build) { build_stubbed(:ci_build) }
  let(:state) { nil }
  let(:data) { StringIO.new('the-stream') }

  let(:stream) do
    Gitlab::Ci::Trace::Stream.new { data }
  end

  subject { described_class.new(build: build, stream: stream, state: state, content_format: content_format) }

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

  context 'with :json content format' do
    let(:content_format) { :json }

    it_behaves_like 'delegates methods'

    it { is_expected.to be_json }

    it 'returns formatted trace' do
      expect(subject.trace.lines).to eq([
        { offset: 0, content: [{ text: 'the-stream' }] }
      ])
    end
  end

  context 'with :html content format' do
    let(:content_format) { :html }

    it_behaves_like 'delegates methods'

    it { is_expected.to be_html }

    it 'returns formatted trace' do
      expect(subject.trace.html).to eq('<span>the-stream</span>')
    end
  end
end
