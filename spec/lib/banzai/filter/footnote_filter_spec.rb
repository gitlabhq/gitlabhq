# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::FootnoteFilter do
  include FilterSpecHelper

  # first[^1] and second[^second]
  # [^1]: one
  # [^second]: two
  let(:footnote) do
    <<-EOF.strip_heredoc
    <p>first<sup><a href="#fn1" id="fnref1">1</a></sup> and second<sup><a href="#fn2" id="fnref2">2</a></sup></p>
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

  context 'when footnotes exist' do
    let(:doc)        { filter(footnote) }
    let(:link_node)  { doc.css('sup > a').first }
    let(:identifier) { link_node[:id].delete_prefix('fnref1-') }

    it 'adds identifier to footnotes' do
      expect(link_node[:id]).to eq "fnref1-#{identifier}"
      expect(link_node[:href]).to eq "#fn1-#{identifier}"
      expect(doc.css("li[id=fn1-#{identifier}]")).not_to be_empty
      expect(doc.css("li[id=fn1-#{identifier}] a[href=\"#fnref1-#{identifier}\"]")).not_to be_empty
    end

    it 'uses the same identifier for all footnotes' do
      expect(doc.css("li[id=fn2-#{identifier}]")).not_to be_empty
      expect(doc.css("li[id=fn2-#{identifier}] a[href=\"#fnref2-#{identifier}\"]")).not_to be_empty
    end

    it 'adds section and classes' do
      expect(doc.css("section[class=footnotes]")).not_to be_empty
      expect(doc.css("sup[class=footnote-ref]").count).to eq 2
      expect(doc.css("a[class=footnote-backref]").count).to eq 2
    end
  end
end
