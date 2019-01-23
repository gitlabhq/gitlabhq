# frozen_string_literal: true

require 'spec_helper'

describe Blobs::UnfoldPresenter do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:blob) { fake_blob(path: 'foo', data: "1\n2\n3") }
  let(:subject) { described_class.new(blob, params) }

  describe '#initialize' do
    context 'when full is false' do
      let(:params) { { full: false, since: 2, to: 3, bottom: false, offset: 1, indent: 1 } }

      it 'sets attributes' do
        result = subject

        expect(result.full?).to eq(false)
        expect(result.since).to eq(2)
        expect(result.to).to eq(3)
        expect(result.bottom).to eq(false)
        expect(result.offset).to eq(1)
        expect(result.indent).to eq(1)
      end
    end

    context 'when full is true' do
      let(:params) { { full: true, since: 2, to: 3, bottom: false, offset: 1, indent: 1 } }

      it 'sets other attributes' do
        result = subject

        expect(result.full?).to eq(true)
        expect(result.since).to eq(1)
        expect(result.to).to eq(blob.lines.size)
        expect(result.bottom).to eq(false)
        expect(result.offset).to eq(0)
        expect(result.indent).to eq(0)
      end
    end
  end

  describe '#lines' do
    context 'when scope is specified' do
      let(:params) { { since: 2, to: 3 } }

      it 'returns lines cropped by params' do
        expect(subject.lines.size).to eq(2)
        expect(subject.lines[0]).to include('LC2')
        expect(subject.lines[1]).to include('LC3')
      end
    end

    context 'when full is true' do
      let(:params) { { full: true } }

      it 'returns all lines' do
        expect(subject.lines.size).to eq(3)
        expect(subject.lines[0]).to include('LC1')
        expect(subject.lines[1]).to include('LC2')
        expect(subject.lines[2]).to include('LC3')
      end
    end
  end

  describe '#match_line_text' do
    context 'when bottom is true' do
      let(:params) { { since: 2, to: 3, bottom: true } }

      it 'returns empty string' do
        expect(subject.match_line_text).to eq('')
      end
    end

    context 'when bottom is false' do
      let(:params) { { since: 2, to: 3, bottom: false } }

      it 'returns match line string' do
        expect(subject.match_line_text).to eq("@@ -2,1+2,1 @@")
      end
    end
  end
end
