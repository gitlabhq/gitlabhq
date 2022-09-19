# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::WordDiff::LineProcessor do
  subject(:line_processor) { described_class.new(line) }

  describe '#extract' do
    subject(:segment) { line_processor.extract }

    context 'when line is a diff hunk' do
      let(:line) { "@@ -1,14 +1,13 @@\n" }

      it 'returns DiffHunk segment' do
        expect(segment).to be_a(Gitlab::WordDiff::Segments::DiffHunk)
        expect(segment.to_s).to eq('@@ -1,14 +1,13 @@')
      end
    end

    context 'when line has a newline delimiter' do
      let(:line) { "~\n" }

      it 'returns Newline segment' do
        expect(segment).to be_a(Gitlab::WordDiff::Segments::Newline)
        expect(segment.to_s).to eq('')
      end
    end

    context 'when line has only space' do
      let(:line) { " \n" }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when line has content' do
      let(:line) { "+New addition\n" }

      it 'returns Chunk segment' do
        expect(segment).to be_a(Gitlab::WordDiff::Segments::Chunk)
        expect(segment.to_s).to eq('New addition')
      end
    end
  end
end
