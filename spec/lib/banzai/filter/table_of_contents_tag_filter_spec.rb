# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TableOfContentsTagFilter do
  include FilterSpecHelper

  context 'table of contents' do
    let(:html) { '<p>[[<em>TOC</em>]]</p>' }

    it 'replaces [[<em>TOC</em>]] with ToC result' do
      doc = filter(html, {}, { toc: "FOO" })

      expect(doc.to_html).to eq("FOO")
    end

    it 'handles an empty ToC result' do
      doc = filter(html)

      expect(doc.to_html).to eq ''
    end
  end
end
