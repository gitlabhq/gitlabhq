# frozen_string_literal: true

require 'spec_helper'

describe BuildTraceEntity do
  let(:build) { build_stubbed(:ci_build) }
  let(:request) { double('request') }

  let(:stream) do
    Gitlab::Ci::Trace::Stream.new do
      StringIO.new('the-trace')
    end
  end

  let(:build_trace) do
    Ci::BuildTrace.new(build: build, stream: stream, content_format: content_format, state: nil)
  end

  let(:entity) do
    described_class.new(build_trace, request: request)
  end

  subject { entity.as_json }

  shared_examples 'includes build and trace metadata' do
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
  end

  context 'when content format is :json' do
    let(:content_format) { :json }

    it_behaves_like 'includes build and trace metadata'

    it 'includes the trace content in json' do
      expect(subject[:lines]).to eq([
        { offset: 0, content: [{ text: 'the-trace' }] }
      ])
    end
  end

  context 'when content format is :html' do
    let(:content_format) { :html }

    it_behaves_like 'includes build and trace metadata'

    it 'includes the trace content in json' do
      expect(subject[:html]).to eq('<span>the-trace</span>')
    end
  end
end
