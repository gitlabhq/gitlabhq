# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::FootnoteFilter, feature_category: :markdown do
  include FilterSpecHelper
  using RSpec::Parameterized::TableSyntax

  # rubocop:disable Style/AsciiComments
  # first[^1] and second[^second] and third[^_😄_]
  # [^1]: one
  # [^second]: two
  # [^_😄_]: three
  # rubocop:enable Style/AsciiComments
  let(:footnote) do
    <<~EOF.strip_heredoc
      <p>first<sup><a href="#fn-1" id="fnref-1" data-footnote-ref>1</a></sup> and second<sup><a href="#fn-second" id="fnref-second" data-footnote-ref>2</a></sup> and third<sup><a href="#fn-_%F0%9F%98%84_" id="fnref-_%F0%9F%98%84_" data-footnote-ref>3</a></sup></p>
      <p>missing id<sup><a href="#fn-10" data-footnote-ref>1</a></sup></p>
      <section data-footnotes>
      <ol>
      <li id="fn-1">
      <p>one <a href="#fnref-1" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1" title="Back to reference 1">↩</a></p>
      </li>
      <li id="fn-second">
      <p>two <a href="#fnref-second" data-footnote-backref data-footnote-backref-idx="2" aria-label="Back to reference 2" title="Back to reference 2">↩</a></p>
      </li>\n<li id="fn-_%F0%9F%98%84_">
      <p>three <a href="#fnref-_%F0%9F%98%84_" data-footnote-backref data-footnote-backref-idx="3" aria-label="Back to reference 3" title="Back to reference 3">↩</a></p>
      </li>
      </ol>
    EOF
  end

  let(:filtered_footnote) do
    <<~EOF.strip_heredoc
      <p>first<sup class="footnote-ref"><a href="#fn-1-#{identifier}" id="fnref-1-#{identifier}" data-footnote-ref>1</a></sup> and second<sup class="footnote-ref"><a href="#fn-second-#{identifier}" id="fnref-second-#{identifier}" data-footnote-ref>2</a></sup> and third<sup class="footnote-ref"><a href="#fn-_%F0%9F%98%84_-#{identifier}" id="fnref-_%F0%9F%98%84_-#{identifier}" data-footnote-ref>3</a></sup></p>
      <p>missing id<sup><a href="#fn-10" data-footnote-ref>1</a></sup></p>
      <section data-footnotes class=\"footnotes\">
      <ol>
      <li id="fn-1-#{identifier}">
      <p>one <a href="#fnref-1-#{identifier}" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1" title="Back to reference 1" class="footnote-backref">↩</a></p>
      </li>
      <li id="fn-second-#{identifier}">
      <p>two <a href="#fnref-second-#{identifier}" data-footnote-backref data-footnote-backref-idx="2" aria-label="Back to reference 2" title="Back to reference 2" class="footnote-backref">↩</a></p>
      </li>
      <li id="fn-_%F0%9F%98%84_-#{identifier}">
      <p>three <a href="#fnref-_%F0%9F%98%84_-#{identifier}" data-footnote-backref data-footnote-backref-idx="3" aria-label="Back to reference 3" title="Back to reference 3" class="footnote-backref">↩</a></p>
      </li>
      </ol>
      </section>
    EOF
  end

  context 'when footnotes exist' do
    let(:doc)        { filter(footnote) }
    let(:link_node)  { doc.css('sup > a').first }
    let(:identifier) { link_node[:id].delete_prefix('fnref-1-') }

    it 'properly adds the necessary ids and classes' do
      expect(doc.to_html).to eq filtered_footnote.strip
    end

    context 'when GITLAB_TEST_FOOTNOTE_ID is set' do
      let(:test_footnote_id) { '42' }
      let(:identifier) { test_footnote_id }

      before do
        stub_env('GITLAB_TEST_FOOTNOTE_ID', test_footnote_id)
      end

      it 'uses the test footnote ID instead of a random number' do
        expect(doc.to_html).to eq filtered_footnote.strip
      end
    end
  end

  context 'when detecting footnotes' do
    where(:valid, :markdown) do
      true   | "1. one[^1]\n[^1]: AbC"
      true   | "1. one[^abc]\n[^abc]: AbC"
      false  | '1. [one](#fnref-abc)'
      false  | "1. one[^1]\n[^abc]: AbC"
    end

    with_them do
      it 'detects valid footnotes' do
        result = Banzai::Pipeline::FullPipeline.call(markdown, project: nil)

        expect(result[:output].at_css('section.footnotes').present?).to eq(valid)
      end
    end
  end

  context 'when too many footnotes' do
    it 'ignores them all' do
      markdown = "[^1]\n[^1]:\n" * (Banzai::Filter::FootnoteFilter::FOOTNOTE_LIMIT + 1)
      result = Banzai::Pipeline::FullPipeline.call(markdown, project: nil)

      expect(result[:output].at_css('section.footnotes').present?).to be_falsey
    end
  end

  it_behaves_like 'pipeline timing check'
end
