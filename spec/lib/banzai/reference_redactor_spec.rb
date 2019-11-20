# frozen_string_literal: true

require 'spec_helper'

describe Banzai::ReferenceRedactor do
  let(:user) { create(:user) }
  let(:project) { build(:project) }
  let(:redactor) { described_class.new(Banzai::RenderContext.new(project, user)) }

  describe '#redact' do
    context 'when reference not visible to user' do
      before do
        expect(redactor).to receive(:nodes_visible_to_user).and_return([])
      end

      it 'redacts an array of documents' do
        doc1 = Nokogiri::HTML
               .fragment('<a class="gfm" href="https://www.gitlab.com" data-reference-type="issue">foo</a>')

        doc2 = Nokogiri::HTML
               .fragment('<a class="gfm" href="https://www.gitlab.com" data-reference-type="issue">bar</a>')

        redacted_data = redactor.redact([doc1, doc2])

        expect(redacted_data.map { |data| data[:document] }).to eq([doc1, doc2])
        expect(redacted_data.map { |data| data[:visible_reference_count] }).to eq([0, 0])
        expect(doc1.to_html).to eq('foo')
        expect(doc2.to_html).to eq('bar')
      end

      it 'replaces redacted reference with inner HTML' do
        doc = Nokogiri::HTML.fragment("<a class='gfm' href='https://www.gitlab.com' data-reference-type='issue'>foo</a>")
        redactor.redact([doc])
        expect(doc.to_html).to eq('foo')
      end

      context 'when data-original attribute provided' do
        let(:original_content) { '<code>foo</code>' }
        it 'replaces redacted reference with original content' do
          doc = Nokogiri::HTML.fragment("<a class='gfm' href='https://www.gitlab.com' data-reference-type='issue' data-original='#{original_content}'>bar</a>")
          redactor.redact([doc])
          expect(doc.to_html).to eq(original_content)
        end

        it 'does not replace redacted reference with original content if href is given' do
          html = "<a href='https://www.gitlab.com' data-link-reference='true' class='gfm' data-reference-type='issue' data-reference-type='issue' data-original='Marge'>Marge</a>"
          doc = Nokogiri::HTML.fragment(html)
          redactor.redact([doc])
          expect(doc.to_html).to eq('<a href="https://www.gitlab.com">Marge</a>')
        end

        it 'uses the original content as the link content if given' do
          html = "<a href='https://www.gitlab.com' data-link-reference='true' class='gfm' data-reference-type='issue' data-reference-type='issue' data-original='Homer'>Marge</a>"
          doc = Nokogiri::HTML.fragment(html)
          redactor.redact([doc])
          expect(doc.to_html).to eq('<a href="https://www.gitlab.com">Homer</a>')
        end
      end
    end

    context 'when project is in pending delete' do
      let!(:issue) { create(:issue, project: project) }
      let(:redactor) { described_class.new(Banzai::RenderContext.new(project, user)) }

      before do
        project.update(pending_delete: true)
      end

      it 'redacts an issue attached' do
        doc = Nokogiri::HTML.fragment("<a class='gfm' href='https://www.gitlab.com' data-reference-type='issue' data-issue='#{issue.id}'>foo</a>")

        redactor.redact([doc])

        expect(doc.to_html).to eq('foo')
      end

      it 'redacts an external issue' do
        doc = Nokogiri::HTML.fragment("<a class='gfm' href='https://www.gitlab.com' data-reference-type='issue' data-external-issue='#{issue.id}' data-project='#{project.id}'>foo</a>")

        redactor.redact([doc])

        expect(doc.to_html).to eq('foo')
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

  context 'when the user cannot read cross project' do
    include ActionView::Helpers::UrlHelper
    let(:project) { create(:project) }
    let(:other_project) { create(:project, :public) }

    def create_link(issuable)
      type = issuable.class.name.underscore.downcase
      link_to(issuable.to_reference, '',
              class: 'gfm has-tooltip',
              title: issuable.title,
              data: {
                reference_type: type,
                "#{type}": issuable.id
              })
    end

    before do
      project.add_developer(user)

      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_cross_project, :global) { false }
      allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
    end

    it 'skips links to issues within the same project' do
      issue = create(:issue, project: project)
      link = create_link(issue)
      doc = Nokogiri::HTML.fragment(link)

      redactor.redact([doc])
      result = doc.css('a').last

      expect(result['class']).to include('has-tooltip')
      expect(result['title']).to eq(issue.title)
    end

    it 'removes info from a cross project reference' do
      issue = create(:issue, project: other_project)
      link = create_link(issue)
      doc = Nokogiri::HTML.fragment(link)

      redactor.redact([doc])
      result = doc.css('a').last

      expect(result['class']).not_to include('has-tooltip')
      expect(result['title']).to be_empty
    end
  end

  describe '#redact_nodes' do
    it 'redacts an Array of nodes' do
      doc = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      node = doc.children[0]

      expect(redactor).to receive(:nodes_visible_to_user)
        .with([node])
        .and_return(Set.new)

      redactor.redact_document_nodes([{ document: doc, nodes: [node] }])

      expect(doc.to_html).to eq('foo')
    end
  end

  describe '#nodes_visible_to_user' do
    it 'returns a Set containing the visible nodes' do
      doc = Nokogiri::HTML.fragment('<a data-reference-type="issue"></a>')
      node = doc.children[0]

      expect_next_instance_of(Banzai::ReferenceParser::IssueParser) do |instance|
        expect(instance).to receive(:nodes_visible_to_user)
          .with(user, [node])
          .and_return([node])
      end

      expect(redactor.nodes_visible_to_user([node])).to eq(Set.new([node]))
    end
  end
end
