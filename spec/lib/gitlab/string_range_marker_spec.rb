# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StringRangeMarker, feature_category: :source_code_management do
  describe '#mark' do
    def mark_diff(rich = nil)
      raw = 'abc <def>'
      inline_diffs = [2..5]

      described_class.new(raw, rich).mark(inline_diffs) do |text, left:, right:, mode:|
        "LEFT#{text}RIGHT".html_safe
      end
    end

    context "when the rich text is html safe" do
      let(:rich) { %(<span class="abc">abc</span><span class="space"> </span><span class="def">&lt;def&gt;</span>).html_safe }

      it 'marks the inline diffs' do
        expect(mark_diff(rich)).to eq(%(<span class="abc">abLEFTcRIGHT</span><span class="space">LEFT RIGHT</span><span class="def">LEFT&lt;dRIGHTef&gt;</span>))
        expect(mark_diff(rich)).to be_html_safe
      end
    end

    context "when the rich text is not html safe" do
      context 'when rich text equals raw text' do
        it 'marks the inline diffs' do
          expect(mark_diff).to eq(%(abLEFTc <dRIGHTef>))
          expect(mark_diff).not_to be_html_safe
        end
      end

      context 'when rich text doeas not equal raw text' do
        let(:rich)  { "abc <def> differs" }

        it 'marks the inline diffs' do
          expect(mark_diff(rich)).to eq(%(abLEFTc &lt;dRIGHTef&gt; differs))
          expect(mark_diff(rich)).to be_html_safe
        end
      end
    end

    context 'when original_text is nil due to out-of-bounds offset' do
      it 'does not raise and returns the rich line' do
        raw = 'a' * 200
        rich = ('a' * 100).html_safe
        ranges = [150..160]

        marker = described_class.new(raw, rich)

        result = marker.mark(ranges) { |text, left:, right:, mode:| "<mark>#{text}</mark>" }

        expect(result).to eq('a' * 100)
      end
    end

    shared_examples 'bounds-checked position mapping' do
      let(:ranges) { [0..(raw.length - 1)] }

      subject(:result) do
        described_class.new(raw, rich).mark(ranges) do |text, left:, right:, mode:|
          "<mark>#{text}</mark>".html_safe
        end
      end

      context 'when commit description contains URLs with query parameters' do
        let(:raw) { 'http://example.com/?foo=1&bar=2' }
        let(:rich) { 'http://example.com/?foo=1&amp;bar=2'.html_safe }

        it 'wraps the entire URL including the html-escaped ampersand' do
          expect(result).to eq('<mark>http://example.com/?foo=1&amp;bar=2</mark>')
          expect(result).to be_html_safe
        end
      end

      context 'when rich_line is exhausted before raw_line' do
        let(:raw) { 'hello world' }
        let(:rich) { 'hello'.html_safe }
        let(:ranges) { [0..4] }

        it 'marks the visible portion and returns html-safe output' do
          expect(result).to eq('<mark>hello</mark>')
          expect(result).to be_html_safe
        end
      end

      context 'when the requested range starts entirely beyond the mapped portion' do
        let(:raw) { 'hello world' }
        let(:rich) { 'hello'.html_safe }
        let(:ranges) { [6..10] }

        it 'skips the out-of-bounds range and returns the unmarked rich line' do
          expect(result).to eq('hello')
          expect(result).to be_html_safe
        end
      end

      context 'when rich_line contains an unclosed HTML tag at the end' do
        let(:raw) { 'test' }
        let(:rich) { 'test<span'.html_safe }

        it 'marks the text before the unclosed tag and preserves the trailing tag fragment' do
          expect(result).to eq('<mark>test</mark><span')
          expect(result).to be_html_safe
        end
      end

      context 'when processing concatenated URLs with query parameters' do
        let(:url_fragment) { 'http://x.com/?a=1&b=2' }
        let(:raw) { CGI.unescapeHTML(url_fragment * 100) }
        let(:rich) { (url_fragment * 100).html_safe }
        let(:ranges) { [0..20] }

        it 'completes without timeout' do
          Timeout.timeout(5) do
            expect(result).to be_html_safe
          end
        end
      end

      context 'when rich_line is shorter than raw_line due to entity expansion' do
        let(:raw) { 'http://x.com/?a=1&b=2' * 2 }
        let(:rich) { ('http://x.com/?a=1&amp;b=2' * 2).html_safe }
        let(:ranges) { [0..(raw.length - 1)] }

        it 'returns the mapped visible portion without error' do
          expect(result).to eq("<mark>#{'http://x.com/?a=1&amp;b=2' * 2}</mark>")
          expect(result).to be_html_safe
        end
      end

      context 'when processing text with many HTML entities from escaped email addresses' do
        let(:raw) { "Author: John Doe <john.doe@example.com>" }
        let(:rich) { "Author: John Doe &lt;john.doe@example.com&gt;".html_safe }
        let(:ranges) { [0..5] }

        it 'marks the correct range spanning plain text' do
          expect(result).to eq('<mark>Author</mark>: John Doe &lt;john.doe@example.com&gt;')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text has no HTML entities' do
        let(:raw) { 'plain text without special chars' }
        let(:rich) { 'plain text without special chars'.html_safe }
        let(:ranges) { [0..4] }

        it 'marks the correct range in plain text' do
          expect(result).to eq('<mark>plain</mark> text without special chars')
          expect(result).to be_html_safe
        end
      end

      context 'when text contains an unclosed HTML entity' do
        let(:raw) { 'a&b' }
        let(:rich) { 'a&amp;b'.html_safe }
        let(:ranges) { [0..2] }

        it 'marks the correct range including the entity' do
          expect(result).to eq('<mark>a&amp;b</mark>')
          expect(result).to be_html_safe
        end
      end

      # The following specs exercise safe_position_mapping directly. mark skips
      # mapping when raw and rich lengths match (identity_mapping?), so each input
      # below keeps raw and rich lengths unequal to force the mapping path, while
      # placing a literal (unescaped) ampersand in the html_safe rich_line.
      #
      context 'when rich text contains a literal ampersand followed by an unrelated semicolon' do
        let(:raw) { 'Tom & Jerry; extra' }
        let(:rich) { 'Tom & Jerry; extra!'.html_safe }
        let(:ranges) { [0..4] }

        it 'maps the literal ampersand 1:1 without overrunning to the semicolon', :aggregate_failures do
          expect(result).to eq('<mark>Tom &</mark> Jerry; extra!')
          expect(result).to be_html_safe
        end
      end

      context 'when a literal ampersand is followed by more rich characters' do
        let(:raw) { 'Tom &' }
        let(:rich) { 'Tom &X more'.html_safe }
        let(:ranges) { [0..4] }

        it 'maps the ampersand 1:1 without dropping subsequent characters', :aggregate_failures do
          expect(result).to eq('<mark>Tom &</mark>X more')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text ends with a literal ampersand' do
        let(:raw) { 'Tom &' }
        let(:rich) { '<b>Tom &</b>'.html_safe }
        let(:ranges) { [0..4] }

        it 'maps the trailing ampersand without overrunning past end-of-string', :aggregate_failures do
          expect(result).to eq('<b><mark>Tom &</mark></b>')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text contains a valid HTML entity (regression guard)' do
        let(:raw) { 'a&b extra' }
        let(:rich) { 'a&amp;b extra!'.html_safe }
        let(:ranges) { [0..2] }

        it 'still collapses the entity to a single raw position', :aggregate_failures do
          expect(result).to eq('<mark>a&amp;b</mark> extra!')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text contains multiple literal ampersands' do
        let(:raw) { 'A & B & C' }
        let(:rich) { 'A & B & C!'.html_safe }
        let(:ranges) { [0..2] }

        it 'maps the first literal ampersand 1:1 without overrunning to a later one', :aggregate_failures do
          expect(result).to eq('<mark>A &</mark> B & C!')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text contains numeric HTML entities' do
        let(:raw) { "a'b/c" }
        let(:rich) { "a&#39;b&#x2F;c extra".html_safe }
        let(:ranges) { [0..4] }

        it 'collapses decimal and hex entities correctly', :aggregate_failures do
          expect(result).to eq("<mark>a&#39;b&#x2F;c</mark> extra")
          expect(result).to be_html_safe
        end
      end

      context 'when rich text contains ampersand-semicolon with no entity name' do
        let(:raw) { 'test &; more' }
        let(:rich) { 'test &; more!'.html_safe }
        let(:ranges) { [0..6] }

        it 'treats &; as two separate characters (not a valid entity)', :aggregate_failures do
          expect(result).to eq('<mark>test &;</mark> more!')
          expect(result).to be_html_safe
        end
      end

      context 'when rich text contains an HTML tag and a literal ampersand' do
        let(:raw) { 'a & b' }
        let(:rich) { '<span>a & b</span> extra'.html_safe }
        let(:ranges) { [0..4] }

        it 'handles both the tag skip and literal ampersand correctly', :aggregate_failures do
          expect(result).to eq('<span><mark>a & b</mark></span> extra')
          expect(result).to be_html_safe
        end
      end

      context 'when multiple ranges span a literal ampersand' do
        let(:raw) { 'Tom & Jerry' }
        let(:rich) { 'Tom & Jerry!'.html_safe }
        let(:ranges) { [0..2, 4..10] }

        it 'marks both ranges correctly without overrunning', :aggregate_failures do
          expect(result).to eq('<mark>Tom</mark> <mark>& Jerry</mark>!')
          expect(result).to be_html_safe
        end
      end

      context 'when a run of bare ampersands precedes a distant semicolon' do
        let(:count) { 5_000 }
        let(:raw) { "#{'&' * count};" }
        # Wrapped in a tag so raw and rich lengths differ; otherwise
        # identity_mapping? short-circuits and safe_position_mapping never runs.
        #
        let(:rich) { "<b>#{'&' * count};</b>".html_safe }
        let(:ranges) { [0..2] }

        it 'maps each bare ampersand 1:1 without scanning to the distant semicolon', :aggregate_failures do
          expect(result).to eq("<b><mark>&&&</mark>#{'&' * (count - 3)};</b>")
          expect(result).to be_html_safe
        end
      end
    end

    it_behaves_like 'bounds-checked position mapping'
  end
end
