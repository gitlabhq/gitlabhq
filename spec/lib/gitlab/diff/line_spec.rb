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
    described_class.new(
      '<input>',
      type,
      0,
      0,
      1,
      parent_file: double(:file),
      line_code: double(:line_code),
      rich_text: rich_text
    )
  end

  let(:type) { 'match' }
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

  describe '#text_content' do
    context 'when has rich text' do
      before do
        line.rich_text = '+<span>added</span>'.html_safe
      end

      it 'returns unprefixed rich text' do
        expect(line.text_content).to eq('<span>added</span>')
        expect(line.text_content.html_safe?).to be(true)
      end
    end

    context 'when has plain text only' do
      before do
        line.text = '+added'
      end

      it 'returns unprefixed plain text' do
        expect(line.text_content).to eq('added')
        expect(line.text_content.html_safe?).to be(false)
      end
    end
  end

  describe '#match?' do
    subject { line.match? }

    context 'when type is "match"' do
      it { is_expected.to be_truthy }

      context 'when feature flag "diff_line_match" is disabled' do
        before do
          stub_feature_flags(diff_line_match: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when type is :match' do
      let(:type) { :match }

      it { is_expected.to be_truthy }
    end

    context 'when type is missing' do
      let(:type) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when type is "old"' do
      let(:type) { 'old' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#expanded?' do
    subject { line.expanded? }

    it { is_expected.to be_falsey }

    context 'when expanded is true' do
      before do
        line.expanded = true
      end

      it { is_expected.to be_truthy }
    end

    context 'when expanded is false' do
      before do
        line.expanded = false
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#id' do
    let(:file_hash) { '1234567890' }

    subject(:id) { line.id(file_hash) }

    context 'when meta line' do
      it { is_expected.to be_nil }
    end

    context 'with added line' do
      let(:line) do
        described_class.new(
          '<input>',
          'new',
          1,
          10,
          11,
          parent_file: double(:file),
          line_code: double(:line_code),
          rich_text: rich_text
        )
      end

      it { is_expected.to eq("line_#{file_hash[0..8]}_A#{line.new_pos}") }
    end

    context 'with unchanged line' do
      let(:line) do
        described_class.new(
          '<input>',
          nil,
          1,
          10,
          11,
          parent_file: double(:file),
          line_code: double(:line_code),
          rich_text: rich_text
        )
      end

      it { is_expected.to eq("line_#{file_hash[0..8]}_#{line.old_pos}") }
    end

    context 'with removed line' do
      let(:line) do
        described_class.new(
          '<input>',
          'old',
          1,
          10,
          11,
          parent_file: double(:file),
          line_code: double(:line_code),
          rich_text: rich_text
        )
      end

      it { is_expected.to eq("line_#{file_hash[0..8]}_#{line.old_pos}") }
    end
  end
end
