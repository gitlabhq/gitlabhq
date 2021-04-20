# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Line do
  shared_examples 'line object initialized by hash' do
    it 'round-trips correctly with to_hash' do
      expect(described_class.safe_init_from_hash(line.to_hash).to_hash)
        .to eq(line.to_hash)
    end
  end

  let(:line) do
    described_class.new('<input>', 'match', 0, 0, 1,
                        parent_file: double(:file),
                        line_code: double(:line_code),
                        rich_text: rich_text)
  end

  let(:rich_text) { nil }

  describe '.init_from_hash' do
    let(:rich_text) { '&lt;input&gt;' }

    it_behaves_like 'line object initialized by hash'
  end

  describe '.safe_init_from_hash' do
    let(:rich_text) { '<input>' }

    it_behaves_like 'line object initialized by hash'

    it 'ensures rich_text is HTML-safe' do
      expect(line.rich_text).not_to be_html_safe

      new_line = described_class.safe_init_from_hash(line.to_hash)

      expect(new_line.rich_text).to be_html_safe
    end

    context 'when given hash has no rich_text' do
      it_behaves_like 'line object initialized by hash' do
        let(:rich_text) { nil }
      end
    end
  end

  describe '#text' do
    let(:line) { described_class.new(raw_diff, 'new', 0, 0, 0) }
    let(:raw_diff) { '+Hello' }

    it 'returns raw diff text' do
      expect(line.text).to eq('+Hello')
    end

    context 'when prefix is disabled' do
      it 'returns raw diff text without prefix' do
        expect(line.text(prefix: false)).to eq('Hello')
      end

      context 'when diff is empty' do
        let(:raw_diff) { '' }

        it 'returns an empty raw diff' do
          expect(line.text(prefix: false)).to eq('')
        end
      end
    end
  end

  context "when setting rich text" do
    it 'escapes any HTML special characters in the diff chunk header' do
      subject = described_class.new("<input>", "", 0, 0, 0)
      line = subject.as_json

      expect(line[:rich_text]).to eq("&lt;input&gt;")
    end
  end

  describe '#set_marker_ranges' do
    let(:marker_ranges) { [Gitlab::MarkerRange.new(1, 10, mode: :deletion)] }

    it 'stores MarkerRanges in Diff::Line object' do
      line.set_marker_ranges(marker_ranges)

      expect(line.marker_ranges).to eq(marker_ranges)
    end
  end
end
