require 'spec_helper'

describe Banzai::Filter::ReferenceFilter do
  let(:project) { build_stubbed(:project) }

  describe '#each_node' do
    it 'iterates over the nodes in a document' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }
        .to yield_with_args(an_instance_of(Nokogiri::XML::Element))
    end

    it 'returns an Enumerator when no block is given' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect(filter.each_node).to be_an_instance_of(Enumerator)
    end

    it 'skips links with a "gfm" class' do
      document = Nokogiri::HTML.fragment('<a href="foo" class="gfm">foo</a>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }.not_to yield_control
    end

    it 'skips text nodes in pre elements' do
      document = Nokogiri::HTML.fragment('<pre>foo</pre>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }.not_to yield_control
    end
  end

  describe '#nodes' do
    it 'returns an Array of the HTML nodes' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect(filter.nodes).to eq([document.children[0]])
    end
  end
end
