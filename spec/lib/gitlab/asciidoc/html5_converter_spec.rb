# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Asciidoc::Html5Converter do
  describe 'convert AsciiDoc to HTML5' do
    it 'appends user-content- prefix on ref (anchor)' do
      doc = Asciidoctor::Document.new('')
      anchor = Asciidoctor::Inline.new(doc, :anchor, '', type: :ref, id: 'cross-references')
      converter = described_class.new('gitlab_html5')
      html = converter.convert_inline_anchor(anchor)
      expect(html).to eq('<a id="user-content-cross-references"></a>')
    end
  end
end
