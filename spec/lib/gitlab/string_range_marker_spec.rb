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
    end

    it_behaves_like 'bounds-checked position mapping'

    context 'when fix_string_range_marker_infinite_loop is disabled' do
      before do
        stub_feature_flags(fix_string_range_marker_infinite_loop: false)
      end

      context 'when rich line contains HTML tags' do
        let(:raw) { 'abc <def>' }
        let(:rich) { %(<span class="abc">abc</span><span class="space"> </span><span class="def">&lt;def&gt;</span>).html_safe }

        it 'correctly skips HTML tags and maps entities' do
          ranges = [2..5]
          marker = described_class.new(raw, rich)
          result = marker.mark(ranges) { |text, left:, right:, mode:| "LEFT#{text}RIGHT".html_safe }

          expect(result).to eq(%(<span class="abc">abLEFTcRIGHT</span><span class="space">LEFT RIGHT</span><span class="def">LEFT&lt;dRIGHTef&gt;</span>))
          expect(result).to be_html_safe
        end
      end

      context 'when rich line contains HTML entities' do
        let(:raw) { 'http://example.com/?foo=1&bar=2' }
        let(:rich) { 'http://example.com/?foo=1&amp;bar=2'.html_safe }

        it 'maps multi-char HTML entities to single raw characters' do
          ranges = [0..(raw.length - 1)]
          marker = described_class.new(raw, rich)
          result = marker.mark(ranges) { |text, left:, right:, mode:| "<mark>#{text}</mark>".html_safe }

          expect(result).to eq('<mark>http://example.com/?foo=1&amp;bar=2</mark>')
          expect(result).to be_html_safe
        end
      end

      context 'when the rich text contains HTML tags and entities' do
        let(:rich) { %(<span class="abc">abc</span><span class="space"> </span><span class="def">&lt;def&gt;</span>).html_safe }

        it 'marks the inline diffs correctly' do
          expect(mark_diff(rich)).to eq(%(<span class="abc">abLEFTcRIGHT</span><span class="space">LEFT RIGHT</span><span class="def">LEFT&lt;dRIGHTef&gt;</span>))
          expect(mark_diff(rich)).to be_html_safe
        end
      end

      context 'when marker range exceeds rich line length' do
        it 'does not raise due to nil guard' do
          raw = 'a' * 200
          rich = ('a' * 100).html_safe
          ranges = [150..160]

          marker = described_class.new(raw, rich)

          result = marker.mark(ranges) { |text, left:, right:, mode:| "<mark>#{text}</mark>" }

          expect(result).to eq('a' * 100)
        end
      end
    end
  end
end
