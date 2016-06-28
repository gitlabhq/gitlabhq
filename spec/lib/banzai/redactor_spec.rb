require 'spec_helper'

describe Banzai::Redactor do
  let(:user) { build(:user) }
  let(:project) { build(:empty_project) }
  let(:redactor) { described_class.new(project, user) }

  describe '#redact' do
    it 'redacts an Array of documents' do
      doc1 = Nokogiri::HTML.
        fragment('<a class="gfm" data-reference-type="issue">foo</a>')

      doc2 = Nokogiri::HTML.
        fragment('<a class="gfm" data-reference-type="issue">bar</a>')

      expect(redactor).to receive(:nodes_visible_to_user).and_return([])

      expect(redactor.redact([doc1, doc2])).to eq([doc1, doc2])

      expect(doc1.to_html).to eq('foo')
      expect(doc2.to_html).to eq('bar')
    end
  end

  describe '#redact_nodes' do
    it 'redacts an Array of nodes' do
      doc = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      node = doc.children[0]

      expect(redactor).to receive(:nodes_visible_to_user).
        with([node]).
        and_return(Set.new)

      redactor.redact_nodes([node])

      expect(doc.to_html).to eq('foo')
    end
  end

  describe '#nodes_visible_to_user' do
    it 'returns a Set containing the visible nodes' do
      doc = Nokogiri::HTML.fragment('<a data-reference-type="issue"></a>')
      node = doc.children[0]

      expect_any_instance_of(Banzai::ReferenceParser::IssueParser).
        to receive(:nodes_visible_to_user).
        with(user, [node]).
        and_return([node])

      expect(redactor.nodes_visible_to_user([node])).to eq(Set.new([node]))
    end
  end
end
