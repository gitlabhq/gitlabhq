# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blobs::UnfoldPresenter do
  include FakeBlobHelpers

  let(:project) { nil } # Project object is not needed but `fake_blob` helper requires it to be defined.
  let(:blob) { fake_blob(path: 'foo', data: data) }
  let(:data) { "1\n\2\n3" }

  subject(:result) { described_class.new(blob, params) }

  describe '#initialize' do
    context 'with empty params' do
      let(:params) { {} }

      it 'sets default attributes' do
        expect(result.full?).to eq(false)
        expect(result.since).to eq(1)
        expect(result.to).to eq(1)
        expect(result.bottom).to eq(false)
        expect(result.unfold).to eq(true)
        expect(result.offset).to eq(0)
        expect(result.indent).to eq(0)
      end
    end

    context 'when full is false' do
      let(:params) { { full: false, since: 2, to: 3, bottom: false, offset: 1, indent: 1 } }

      it 'sets attributes' do
        expect(result.full?).to eq(false)
        expect(result.since).to eq(2)
        expect(result.to).to eq(3)
        expect(result.bottom).to eq(false)
        expect(result.unfold).to eq(true)
        expect(result.offset).to eq(1)
        expect(result.indent).to eq(1)
      end
    end

    context 'when full is true' do
      let(:params) { { full: true, since: 2, to: 3, bottom: false, offset: 1, indent: 1 } }

      it 'sets other attributes' do
        expect(result.full?).to eq(true)
        expect(result.since).to eq(1)
        expect(result.to).to eq(blob.lines.size)
        expect(result.bottom).to eq(false)
        expect(result.unfold).to eq(false)
        expect(result.offset).to eq(0)
        expect(result.indent).to eq(0)
      end
    end

    context 'when to is -1' do
      let(:params) { { full: false, since: 2, to: -1, bottom: true, offset: 1, indent: 1 } }

      it 'sets other attributes' do
        expect(result.full?).to eq(false)
        expect(result.since).to eq(2)
        expect(result.to).to eq(blob.lines.size)
        expect(result.bottom).to eq(false)
        expect(result.unfold).to eq(false)
        expect(result.offset).to eq(0)
        expect(result.indent).to eq(0)
      end
    end
  end

  describe '#diff_lines' do
    let(:total_lines) { 50 }
    let(:data) { (1..total_lines).to_a.join("\n") }

    context 'when "full" is true' do
      let(:params) { { full: true } }

      it 'returns all lines' do
        lines = subject.diff_lines

        expect(lines.size).to eq(total_lines)

        lines.each.with_index do |line, index|
          line_number = index + 1

          expect(line.text).to eq(line_number.to_s)
          expect(line.rich_text).to include("LC#{line_number}")
          expect(line.type).to be_nil
        end
      end

      context 'when last line is empty' do
        let(:data) { "1\n2\n" }

        it 'disregards last line' do
          lines = subject.diff_lines

          expect(lines.size).to eq(2)
        end
      end
    end

    context 'when "since" is equal to 1' do
      let(:params) { { since: 1, to: 10, offset: 10 } }

      it 'does not add top match line' do
        line = subject.diff_lines.first

        expect(line.type).to be_nil
      end
    end

    context 'when "since" is greater than 1' do
      let(:default_params) { { since: 5, to: 10, offset: 10 } }
      let(:params) { default_params }

      it 'adds top match line' do
        line = subject.diff_lines.first

        expect(line.type).to eq('match')
        expect(line.old_pos).to eq(5)
        expect(line.new_pos).to eq(5)
      end

      context 'when "to" is higher than blob size' do
        let(:params) { default_params.merge(to: total_lines + 10, bottom: true) }

        it 'does not add bottom match line' do
          line = subject.diff_lines.last

          expect(line.type).to be_nil
        end
      end

      context 'when "to" is equal to blob size' do
        let(:params) { default_params.merge(to: total_lines, bottom: true) }

        it 'does not add bottom match line' do
          line = subject.diff_lines.last

          expect(line.type).to be_nil
          expect(line.old_pos).to be_nil
          expect(line.new_pos).to be_nil
        end
      end

      context 'when "to" is less than blob size' do
        let(:params) { default_params.merge(to: total_lines - 3, bottom: true) }

        it 'adds bottom match line' do
          line = subject.diff_lines.last

          expect(line.type).to eq('match')
          expect(line.old_pos).to eq(total_lines - 3 - params[:offset])
          expect(line.new_pos).to eq(total_lines - 3)
        end
      end
    end

    context 'when "to" is less than blob size' do
      let(:params) { { since: 1, to: 5, offset: 10, bottom: true } }

      it 'adds bottom match line' do
        line = subject.diff_lines.last

        expect(line.type).to eq('match')
        expect(line.old_pos).to eq(-5)
        expect(line.new_pos).to eq(5)
      end
    end

    context 'when "to" is equal to blob size' do
      let(:params) { { since: 1, to: total_lines, offset: 10, bottom: true } }

      it 'does not add bottom match line' do
        line = subject.diff_lines.last

        expect(line.type).to be_nil
      end
    end

    context 'when "to" is "-1"' do
      let(:params) { { since: 10, to: -1, offset: 10, bottom: true } }

      it 'does not add bottom match line' do
        line = subject.diff_lines.last

        expect(line.type).to be_nil
      end

      it 'last line is the latest blob line' do
        line = subject.diff_lines.last

        expect(line.text).to eq(total_lines.to_s)
      end
    end

    context 'when include_positions is true' do
      let(:params) { { since: 2, to: 5 } }

      it 'adds bottom match line' do
        line = subject.diff_lines(with_positions_and_indent: true)[2]

        expect(line.old_pos).to eq(3)
        expect(line.new_pos).to eq(3)
      end
    end

    context 'when with_positions_and_indent is true' do
      let(:params) { { since: 10, to: 20, offset: 10, bottom: true } }

      it 'adds old_pos and new_pos to lines' do
        line = subject.diff_lines(with_positions_and_indent: true).first

        expect(line.type).to be_nil
        expect(line.old_pos).to eq(0)
        expect(line.new_pos).to eq(10)
      end

      it 'indents the line by 1 space by default' do
        line = subject.diff_lines(with_positions_and_indent: true).first

        expect(line.rich_text[0, 2]).to eq(' <')
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

    context 'when since exceeds number of lines' do
      let(:params) { { since: 2 } }

      it 'returns an empty list' do
        expect(subject.lines.size).to eq(0)
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
