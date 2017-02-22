require 'spec_helper'

describe Banzai::Redactor do
  let(:user) { build(:user) }
  let(:project) { build(:empty_project) }
  let(:redactor) { described_class.new(project, user) }

  describe '#redact' do
    context 'when reference not visible to user' do
      before do
        expect(redactor).to receive(:nodes_visible_to_user).and_return([])
      end

      it 'redacts an array of documents' do
        doc1 = Nokogiri::HTML.
               fragment('<a class="gfm" data-reference-type="issue">foo</a>')

        doc2 = Nokogiri::HTML.
               fragment('<a class="gfm" data-reference-type="issue">bar</a>')

        redacted_data = redactor.redact([doc1, doc2])

        expect(redacted_data.map { |data| data[:document] }).to eq([doc1, doc2])
        expect(redacted_data.map { |data| data[:visible_reference_count] }).to eq([0, 0])
        expect(doc1.to_html).to eq('foo')
        expect(doc2.to_html).to eq('bar')
      end

      it 'replaces redacted reference with inner HTML' do
        doc = Nokogiri::HTML.fragment("<a class='gfm' data-reference-type='issue'>foo</a>")
        redactor.redact([doc])
        expect(doc.to_html).to eq('foo')
      end

      context 'when data-original attribute provided' do
        let(:original_content) { '<code>foo</code>' }
        it 'replaces redacted reference with original content' do
          doc = Nokogiri::HTML.fragment("<a class='gfm' data-reference-type='issue' data-original='#{original_content}'>bar</a>")
          redactor.redact([doc])
          expect(doc.to_html).to eq(original_content)
        end
      end
    end

    context 'when reference visible to user' do
      it 'does not redact an array of documents' do
        doc1_html = '<a class="gfm" data-reference-type="issue">foo</a>'
        doc1 = Nokogiri::HTML.fragment(doc1_html)

        doc2_html = '<a class="gfm" data-reference-type="issue">bar</a>'
        doc2 = Nokogiri::HTML.fragment(doc2_html)

        nodes = redactor.document_nodes([doc1, doc2]).map { |x| x[:nodes] }
        expect(redactor).to receive(:nodes_visible_to_user).and_return(nodes.flatten)

        redacted_data = redactor.redact([doc1, doc2])

        expect(redacted_data.map { |data| data[:document] }).to eq([doc1, doc2])
        expect(redacted_data.map { |data| data[:visible_reference_count] }).to eq([1, 1])
        expect(doc1.to_html).to eq(doc1_html)
        expect(doc2.to_html).to eq(doc2_html)
      end
    end
  end

  describe '#redact_nodes' do
    it 'redacts an Array of nodes' do
      doc = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      node = doc.children[0]

      expect(redactor).to receive(:nodes_visible_to_user).
        with([node]).
        and_return(Set.new)

      redactor.redact_document_nodes([{ document: doc, nodes: [node] }])

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
