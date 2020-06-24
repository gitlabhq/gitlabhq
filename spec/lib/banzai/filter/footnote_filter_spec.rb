# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::FootnoteFilter do
  include FilterSpecHelper

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

  context 'when footnotes exist' do
    let(:doc)        { filter(footnote) }
    let(:link_node)  { doc.css('sup > a').first }
    let(:identifier) { link_node[:id].delete_prefix('fnref1-') }

    it 'properly adds the necessary ids and classes' do
      expect(doc.to_html).to eq filtered_footnote
    end
  end
end
