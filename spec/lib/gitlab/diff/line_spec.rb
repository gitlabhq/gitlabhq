# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::Line do
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

  context "when setting rich text" do
    it 'escapes any HTML special characters in the diff chunk header' do
      subject = described_class.new("<input>", "", 0, 0, 0)
      line = subject.as_json

      expect(line[:rich_text]).to eq("&lt;input&gt;")
    end
  end
end
