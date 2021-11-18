# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::FootnoteFilter do
  include FilterSpecHelper

  # rubocop:disable Style/AsciiComments
  # first[^1] and second[^second] and third[^_😄_]
  # [^1]: one
  # [^second]: two
  # [^_😄_]: three
  # rubocop:enable Style/AsciiComments
  let(:footnote) do
    <<~EOF.strip_heredoc
      <p>first<sup><a href="#fn-1" id="fnref-1">1</a></sup> and second<sup><a href="#fn-second" id="fnref-second">2</a></sup> and third<sup><a href="#fn-_%F0%9F%98%84_" id="fnref-_%F0%9F%98%84_">3</a></sup></p>

      <ol>
      <li id="fn-1">
      <p>one <a href="#fnref-1" aria-label="Back to content">↩</a></p>
      </li>
      <li id="fn-second">
      <p>two <a href="#fnref-second" aria-label="Back to content">↩</a></p>
      </li>\n<li id="fn-_%F0%9F%98%84_">
      <p>three <a href="#fnref-_%F0%9F%98%84_" aria-label="Back to content">↩</a></p>
      </li>
      </ol>
    EOF
  end

  let(:filtered_footnote) do
    <<~EOF.strip_heredoc
      <p>first<sup class="footnote-ref"><a href="#fn-1-#{identifier}" id="fnref-1-#{identifier}" data-footnote-ref="">1</a></sup> and second<sup class="footnote-ref"><a href="#fn-second-#{identifier}" id="fnref-second-#{identifier}" data-footnote-ref="">2</a></sup> and third<sup class="footnote-ref"><a href="#fn-_%F0%9F%98%84_-#{identifier}" id="fnref-_%F0%9F%98%84_-#{identifier}" data-footnote-ref="">3</a></sup></p>

      <section class=\"footnotes\" data-footnotes><ol>
      <li id="fn-1-#{identifier}">
      <p>one <a href="#fnref-1-#{identifier}" aria-label="Back to content" class="footnote-backref" data-footnote-backref="">↩</a></p>
      </li>
      <li id="fn-second-#{identifier}">
      <p>two <a href="#fnref-second-#{identifier}" aria-label="Back to content" class="footnote-backref" data-footnote-backref="">↩</a></p>
      </li>
      <li id="fn-_%F0%9F%98%84_-#{identifier}">
      <p>three <a href="#fnref-_%F0%9F%98%84_-#{identifier}" aria-label="Back to content" class="footnote-backref" data-footnote-backref="">↩</a></p>
      </li>
      </ol></section>
    EOF
  end

  context 'when footnotes exist' do
    let(:doc)        { filter(footnote) }
    let(:link_node)  { doc.css('sup > a').first }
    let(:identifier) { link_node[:id].delete_prefix('fnref-1-') }

    it 'properly adds the necessary ids and classes' do
      expect(doc.to_html).to eq filtered_footnote
    end

    context 'using ruby-based HTML renderer' do
      # first[^1] and second[^second]
      # [^1]: one
      # [^second]: two
      let(:footnote) do
        <<~EOF
          <p>first<sup><a href="#fn1" id="fnref1">1</a></sup> and second<sup><a href="#fn2" id="fnref2">2</a></sup></p>
          <p>same reference<sup><a href="#fn1" id="fnref1">1</a></sup></p>
          <ol>
          <li id="fn1">
          <p>one <a href="#fnref1">↩</a></p>
          </li>
          <li id="fn2">
          <p>two <a href="#fnref2">↩</a></p>
          </li>
          </ol>
        EOF
      end

      let(:filtered_footnote) do
        <<~EOF
          <p>first<sup class="footnote-ref"><a href="#fn1-#{identifier}" id="fnref1-#{identifier}">1</a></sup> and second<sup class="footnote-ref"><a href="#fn2-#{identifier}" id="fnref2-#{identifier}">2</a></sup></p>
          <p>same reference<sup class="footnote-ref"><a href="#fn1-#{identifier}" id="fnref1-#{identifier}">1</a></sup></p>
          <section class="footnotes"><ol>
          <li id="fn1-#{identifier}">
          <p>one <a href="#fnref1-#{identifier}" class="footnote-backref">↩</a></p>
          </li>
          <li id="fn2-#{identifier}">
          <p>two <a href="#fnref2-#{identifier}" class="footnote-backref">↩</a></p>
          </li>
          </ol></section>
        EOF
      end

      let(:doc)        { filter(footnote) }
      let(:identifier) { link_node[:id].delete_prefix('fnref1-') }

      before do
        stub_feature_flags(use_cmark_renderer: false)
      end

      it 'properly adds the necessary ids and classes' do
        expect(doc.to_html).to eq filtered_footnote
      end
    end
  end
end
