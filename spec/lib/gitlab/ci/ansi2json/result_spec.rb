# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Ansi2json::Result do
  let(:stream) { StringIO.new('hello') }
  let(:state) { Gitlab::Ci::Ansi2json::State.new(nil, stream.size) }
  let(:offset) { 0 }
  let(:params) do
    { lines: [], state: state, append: false, truncated: false, offset: offset, stream: stream }
  end

  subject { described_class.new(params) }

  describe '#size' do
    before do
      stream.seek(5) # move stream cursor to the end
    end

    context 'when offset is at the start' do
      let(:offset) { 0 }

      it 'returns the full size' do
        expect(subject.size).to eq(5)
      end
    end

    context 'when offset is not zero' do
      let(:offset) { 2 }

      it 'returns the remaining size' do
        expect(subject.size).to eq(3)
      end
    end
  end

  describe '#total' do
    it 'returns size of stread' do
      expect(subject.total).to eq(5)
    end
  end
end
